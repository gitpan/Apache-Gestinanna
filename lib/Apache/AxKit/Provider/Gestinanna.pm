# $Id: Gestinanna.pm,v 1.1 2004/02/23 21:53:56 jgsmith Exp $

package Apache::AxKit::Provider::Gestinanna;

use strict;
no strict 'refs';
use vars qw/@ISA/;
@ISA = ('Apache::AxKit::Provider');

use Apache;
use Apache::AxKit::Exception;
use Apache::AxKit::Provider;
use Apache::Cookie;
use Apache::Constants qw(OK DECLINED NOT_FOUND SERVER_ERROR);
use Apache::Log;
use Apache::Request;
use Apache::Session::Flex;

use AxKit;

use Gestinanna::POF;
use Gestinanna::Authz;
use Gestinanna::Schema;

use Gestinanna::Request;

use Storable ();

sub new {
    my $class = shift;
    my $apache = shift;
    #my $self = bless { apache => $apache }, $class;
    my $self = bless { apache => Gestinanna::Request -> new($apache) }, $class;
    #warn "Created $self with $apache: $$self{apache}\n";
    
    #eval { $self->init(@_) };
    warn "$@\n" if $@;  # probably should go through Apache's logging mechanism for this stuff
    
    return $self;
}

sub apache_request {
    my $self = shift;
    return $self->{apache};
}

sub read_session {
    my($self, $config, $hash, $id) = @_;

    no strict 'refs';

    eval {
        local($SIG{__DIE__});
        tie %{$hash}, 'Apache::Session::Flex', $id, {
            Commit => 1,
            #%{$c -> session_option || {}},
            Store => $config -> {'session'} -> {'store'} -> {'store'},
            Lock  => $config -> {'session'} -> {'store'} -> {'lock'},
            Generate => $config -> {'session'} -> {'store'} -> {'generate'},
            Serialize => $config -> {'session'} -> {'store'} -> {'serialize'},
            Handle => $self -> {_dbh},
            LockHandle => $self -> {_dbh},
        };
    };
    if($@ || !tied(%$hash)) { # need to check for database errors so we don't thrash about here
        if($@ !~ m{Object does not exist in the data store}) {
            warn "$@\n";
            return undef 
        }
        # bad identifier... need to make a new one and start over
        eval {
            local($SIG{__DIE__});
            tie %{$hash}, 'Apache::Session::Flex', undef, {
                Commit => 1,
                #%{$c -> session_option || {}},
                Store => $config -> {'session'} -> {'store'} -> {'store'},
                Lock  => $config -> {'session'} -> {'store'} -> {'lock'},
                Generate => $config -> {'session'} -> {'store'} -> {'generate'},
                Serialize => $config -> {'session'} -> {'store'} -> {'serialize'},
                Handle => $self -> {_dbh},
                LockHandle => $self -> {_dbh},
            };
        };
        if($@ || !tied(%$hash)) {
            warn "$@\n";
            return;
        }
    }
    return $hash -> {_session_id};
}

sub do_redirect {
    my($self, $url) = @_;

    my $r = $self -> apache_request;

    $r -> err_header_out("Location" => $url);

    my $message = <<EOF;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
  <HEAD>
    <TITLE>Redirecting...</TITLE>
    <META HTTP-EQUIV=Refresh CONTENT="0; URL=$url">
  </HEAD>
  <BODY>
    <H1>Redirecting...</H1>
    You are being redirected <A HREF="$url">here</A>.<P>
  </BODY>
</HTML>
EOF

    $r -> content_type("text/html");
    $r -> send_http_header;
    $r -> print($message);
    $r -> rflush;
}
    

sub init {
    no strict 'refs';

    local($SIG{__DIE__});

    my $self = shift;
#    $self->{data} = $_[0];
#    $self->{styles} = $_[1];

    unless(UNIVERSAL::isa($self -> {apache}, 'Gestinanna::Request')) {
        $self -> {apache} = Gestinanna::Request -> new($self -> {apache});
    }

    my $R = $self -> {apache};

    if(defined $R -> {_decline}) {
        #warn "decline: $$R{_decline}\n";
        $self -> {_decline} = $R -> {_decline};
        return;
    }

    $self -> {_content_provider} = $R -> embeddings or return;
}

sub error { shift -> {apache} -> error_provider(@_); } # for now

sub process {
    my $self = shift;

    if(defined $self -> {_decline}) {
        delete $self -> {_content_provider};
        return;
    }
    return defined $self -> {_content_provider};
}

sub decline {
    my $self = shift;

    if(defined $self -> {_decline}) {
        delete $self -> {_content_provider};
        return $self -> {_decline};
    }
    return NOT_FOUND;
}

sub exists {
    my $self = shift;

    return defined $self -> {_content_provider};
}

sub mtime {
    my $self = shift;

    if(@{$self -> {_content_provider}||[]}) {
        my $mtime;
        foreach my $cp (@{$self -> {_content_provider}||[]}) {
            $mtime = $cp -> mtime if $mtime < $cp -> mtime;
        }
        return $mtime if defined $mtime;
    }

    return time(); # always fresh
}

sub get_fh {
    throw Apache::AxKit::Exception::IO( -text => "Can't get fh for Gestinanna" );
}

sub get_strref {
    my $self = shift;
    return $self->{data} if defined $self -> {data};


    if(defined $self -> {dom}) {
        my $string = $self -> {dom} -> toString(0);
        return $self -> {data} = \$string;
    }
    
    return unless $self -> {_content_provider};

    my $string = $self -> get_dom -> toString(0);
    return $self -> {data} = \$string;
}

sub get_dom {
    my $self = shift;

    return $self -> {dom} if defined $self -> {dom};

    return unless $self -> {_content_provider};

    my $R = $self -> {apache};

    # process embeddings
    my $rootdom;
    my $root;
    if(@{$self -> {_content_provider}||[]}) {
        my $cp = shift @{$self -> {_content_provider}};
        #warn "Root cp: $$cp{type}:$$cp{filename}\n";
        $rootdom = $cp -> dom;
        $rootdom -> setEncoding('utf8');
        $root = $rootdom -> documentElement();
        $root -> setNodeName('page');

        $root -> setAttribute('redirect-url' => $R -> config -> {'redirect-url'})
            if $R -> {_session_id_location} eq 'url';
        $root -> setAttribute('session-id' => $R -> {session} -> {_session_id});

        $self -> {dom} = $rootdom;
    }

    while(@{$self -> {_content_provider}||[]}) {
        my $cp = shift @{$self -> {_content_provider}};
        #warn "  next cp: $$cp{type}:$$cp{filename}\n";
        my $dom = $cp -> dom;
        my $domroot = $dom -> documentElement();
        $rootdom -> adoptNode($domroot);
        $domroot -> setAttribute(id => '_embedded');
        my $boxes = $rootdom -> findnodes('//container[@id = "_embedded" and not(.//container[@id = "_embedded"])]');
        #warn "Got " . scalar($boxes -> get_nodelist) . " boxes\n";
        last unless $boxes -> get_nodelist; # if no embedding, stop since there's no use continuing
        #my @domchildren = $domroot -> childNodes;
        foreach my $box ($boxes -> get_nodelist) {
            $box -> replaceNode( $domroot );
        }
    }

    my $ctx_ids = $rootdom -> findnodes('//stored[@id = "_context_id"]');

    # make sure the session saves
    $R -> {session} -> {mtime} = time() if $ctx_ids -> get_nodelist;

    foreach my $ctx_node ($ctx_ids -> get_nodelist) {
        #my($vn) = ($ctx -> findnodes('value'));
        my $ctx = $ctx_node -> textContent();
        next unless defined $ctx && $ctx ne '';
        my $ancestors = $ctx_node -> findnodes(q{
            ancestor::option[@id != '']
            | ancestor::selection[@id != '']
            | ancestor::group[@id != '']
            | ancestor::form[@id != '']
            | ancestor::container[@id != '']
        });
        my @ids = grep { defined } map { $_ -> getAttribute('id') } $ancestors -> get_nodelist;
        my $id = join(".", @ids);
        #warn "$id._context_id => $ctx\n";
        if($id =~ m{^_embedded(\._embedded)*$}) {
            $R -> {session} -> {contexts} -> {$id} = {
                uri => Apache -> request -> uri,
                ctx => $ctx,
            };
            #warn "embedded context: uri: " . Apache -> request -> uri . " ctx: $ctx\n";
        }
        else {
            $R -> {session} -> {contexts} -> {$id} = $ctx;
        }
    }

    delete $self -> {_content_provider};

    return $self -> {dom};
}

sub DESTROY {
    my $self = shift;

    return ;

    no strict 'refs';

    my $pkg = $self -> config -> {package};

    #warn "Cleaning up session\n";
    untie %{$pkg . "::session"}; # save session
    undef %{$pkg . "::session"};

    return unless $self -> {_cfg};
    
    $self -> {_cfg} -> resources -> {dbi} -> free($self -> {_dbh});
    if($self -> {_ldap}) {
        $self -> {_cfg} -> resources -> {ldap} -> free($self -> {_ldap});
    }
}

sub key {
    my $self = shift;
    return 'gestinanna_provider';
}

#sub get_styles {
#    my $self = shift;
#    return $self->{styles}, [];
#}
my $component = qr{[^\/\@\|\&]+};
        
sub path2regex ($) {
    my $self;
    $self = shift if @_ > 1;
    my $path = shift;
        
    return $self -> {_path_regexen} -> {$path}
        if $self && exists $self -> {_path_regexen} -> {$path};
        
    my @bits; #= split(/\|/, $path);
    foreach my $bit (split(/\s*\|\s*/, $path)) {
        my @xbits = split(/\s*\&\s*/, $bit);
    
        my $t;
        foreach (reverse @xbits) {
            $_ = "\Q$_\E";
            s{^(?:\\!\\!)+(.*)$}{$1};
            s{^\\!(?:\\!\\!)*(.*)$}{(?:(?!$1)|(?:!$1))};
            s{\\/(\\/)+}{\\\/+\((?:$component\\\/+)*\)(?:\\\/)*}g;
            s{\\\*}{\($component\)}g;
            s{\\/}{\\\/}g;
            if($t eq '') {
                $t = $_;
            }
            else {
                $t = "(?(?=$_)(?:$t))"; # hint: regex equiv of ?:
            }
        }
        push @bits, $t;
    }
        
    my $tpath = join(")|(?:", @bits);
        
    $tpath = qr{(?:$tpath)};
        
    return $tpath unless $self;
        
    return $self -> {_path_regexen}->{$path} = $tpath;
}

my $is_regex = qr{^!|//+|\*|\||\&};

sub path_cmp ($$) {
    my $self;

    if(@_ > 2) {
        $self = shift;
    }
    else {
        $self = bless { } => __PACKAGE__;
    }
    

    my($a, $b) = @_;
 
    return 1 if $a eq $b;

    return $self -> {_cmp_cache} -> {$a} -> {$b}
        if exists $self -> {_cmp_cache} -> {$a} -> {$b};
    
    if($a !~ m{$is_regex}) {
        return $self -> {_cmp_cache} -> {$a} -> {$b} = ($a cmp $b ? undef : 1) unless $b =~ m{$is_regex};

        my $bb = $self -> path2regex($b);
        #main::diag("b: $b => $bb");
        return $self -> {_cmp_cache} -> {$a} -> {$b} = -1 if $a =~ m{^$bb$};
        return $self -> {_cmp_cache} -> {$a} -> {$b} = undef unless $a =~ m{^$bb};
        #return $self -> {_cmp_cache} -> {$a} -> {$b} = $b =~ m{\&} ? undef : 1;
    }
    else {
        unless($b =~ m{$is_regex}) {
            my $aa = $self -> path2regex($a);
            #main::diag("a: $a => $aa");
            return $self -> {_cmp_cache} -> {$a} -> {$b} = 1 if $b =~ m{^$aa$};
            return $self -> {_cmp_cache} -> {$a} -> {$b} = undef unless $b =~ m{^$aa};
            #return $self -> {_cmp_cache} -> {$a} -> {$b} = ($a =~ m{\&} ? undef : -1);
        }
            
        my %abits = map { $_ => undef } split(/\s*\|\s*/, $a);
        my %bbits = map { $_ => undef } split(/\s*\|\s*/, $b);
        my $alla = scalar keys %abits;
        my $allb = scalar keys %bbits;
                
        return $self -> {_cmp_cache} -> {$a} -> {$b} = 1 unless $alla || $allb;
         
        return $self -> {_cmp_cache} -> {$a} -> {$b} = 1  if  $alla && !$allb;
        return $self -> {_cmp_cache} -> {$a} -> {$b} = -1 if !$alla &&  $allb;

        my $aa = $self -> path2regex(join("|", keys %abits));
        my $bb = $self -> path2regex(join("|", keys %bbits));
    
        # if a =~ B, then a <= B
        #main::diag("b: $bb");
        foreach my $p (keys %abits) {
            $abits{$p} = $p =~ m{^$bb$};
            #main::diag("a: $p => $abits{$p}");
        }
        #main::diag("a: $aa");
        foreach my $p (keys %bbits) {
            $bbits{$p} = $p =~ m{^$aa$};
            #main::diag("b: $p => $bbits{$p}");
        }
    
        my $numa = scalar(grep { $_ } values %abits);
        my $numb = scalar(grep { $_ } values %bbits);
    
        #main::diag("$a <=> $b: ($numa/$alla : $numb/$allb)");
     
        return $self -> {_cmp_cache} -> {$a} -> {$b} = undef if $numa == 0 && $numb == 0;   # disjoint

        return $self -> {_cmp_cache} -> {$a} -> {$b} = 1 if $numa <= $alla && $numb == $allb;  # A <= B

        return $self -> {_cmp_cache} -> {$a} -> {$b} = -1 if $numa == $alla && $numb < $allb;  # B < A

        return $self -> {_cmp_cache} -> {$a} -> {$b} = 0;  # overlap
    }
}


1;
