package Apache::Gestinanna;

use Apache::ModuleConfig;
use ResourcePool;
use ResourcePool::LoadBalancer;
use DBI;

use Gestinanna::POF;
use Gestinanna::Schema;

use Apache::AxKit::Provider::Gestinanna;

our $VERSION = '0.01';

use XML::Simple;

use strict;

if($ENV{MOD_PERL}) {
    if($mod_perl::VERSION < 1.99) {  
        our @ISA = qw(DynaLoader);
        __PACKAGE__ -> bootstrap($VERSION);
    }
}

sub request {
    return Apache::Gestinanna::Request -> new;
}

sub GestinannaConf ($$$;*) {
    my($cfg, $param, $file, $fh) = @_;

    my @files;

    # "..." or ...(no spaces)
    @files = map {
        $_ !~ m{^/} 
           ? Apache->server_root_relative($_)
           : $_
    } grep { defined $_ } ($file =~ m{"((?:\\"|[^"]+)*)"|([^"\s]+)}g);

    my $config = { };
    my $xs = new XML::Simple(
        ContentKey => '-content',
        ForceArray => [qw(
        )],
        GroupTags => {
            'tag-path' => 'tag',
        },
        KeyAttr => {
            'content-provider' => 'type',
            'data-provider' => 'type',
        },
        NormaliseSpace => 2,
        VarAttr => 'id',
    );

    warn "GestinannaConf: Only parsing first file ($files[0])\n" if @files > 1;

    $config = $xs -> XMLin($files[0]);

    $cfg -> {resource_config} = $config;

    my ($schema, $site) = delete @{$cfg -> {resource_config}}{qw(schema site)};

    #$cfg -> {prefork_resources} = $cfg -> make_resources('prefork_');

    Apache -> push_handlers(PerlChildInitHandler => sub {
        $cfg -> {resources} = $cfg -> make_resources;
    });

    # load configuration from database
    #my $dbh = $cfg -> {prefork_resources} -> {prefork_dbi} -> get();
    my $dbh;
    foreach my $r (@{$cfg->{resource_config}->{pool}||[]}) {
        if(defined $r->{dbi}) {
            eval { $dbh = DBI->connect(
                $r -> {dbi} -> {datasource}, 
                $r -> {dbi} -> {username}, 
                $r -> {dbi} -> {password},
                {
                    map { $_ => $r -> {dbi} -> {$_} } grep { /^[A-Z]/ } keys %{$r -> {dbi}}
                },
            ); };
            last unless $@;
            warn "$@\n";
        }
    }
    

    eval { Gestinanna::Schema -> make_methods( name => $schema ); };
    warn "$@\n" if $@;  # might be errors if already done, but this can be useful for XSM

    my $alzabo_schema = Gestinanna::Schema -> load_schema(
        name => $schema,
        dbh => $dbh
    );

    my $site_data = $alzabo_schema -> table('Site') -> row_by_pk( pk => $site );
    $config = $xs -> XMLin($site_data -> select('configuration') || "<configuration/>");

    $dbh -> disconnect;

    $cfg -> {config} = $config;
    $cfg -> {config} -> {schema} = $schema;
    $cfg -> {config} -> {site} = $site;

    # pre-load classes
    foreach my $t (qw(content-provider data-provider)) {
        foreach my $ct (keys %{$config -> {$t} || {}}) {
            my $class = $config -> {$t} -> {$ct} -> {'class'};
            next unless defined $class;
            warn "Requiring [$class]\n";
            eval "require $class;";
            if($@) {
                warn "Removing $t $ct: $@\n";
                delete $config -> {$t} -> {$ct};
            }
            elsif($class -> can('config')) {
                eval {
                    $class -> config($config -> {$t} -> {$ct} -> {config});
                };
                if($@) {
                    warn "Removing $t $ct: $@\n";
                    delete $config -> {$t} -> {$ct};
                }
            }
        }
    }

    my $factory_class = $config -> {package} . "::POF";
    { no strict 'refs';
      @{$factory_class . "::ISA"} = qw(Gestinanna::POF);
    }
    my $base_pkg = $config -> {'package'} . "::DataProviders::";
    foreach my $type (keys %{$config -> {'data-provider'}||{}}) {
        my $class = $config -> {'data-provider'} -> {$type} -> {class};
        unless(defined $class) {
            # load info and create class
            my $c = $config -> {'data-provider'} -> {$type};
            $class = $base_pkg . $type;
            $class =~ tr[-][_];
            my $code;
            my @classes;

            # may want security options here
            if($c -> {'security'} eq 'read-only') {
                push @classes, 'Gestinanna::POF::Secure::ReadOnly';
            }
            elsif($c -> {'security'} eq 'read-write') {
                push @classes, 'Gestinanna::POF::Secure::Gestinanna';
            }

            if($c -> {'data-type'} eq 'alzabo') {
                push @classes, 'Gestinanna::POF::Alzabo';
                my $table = $c -> {'table'};
                $code = <<1HERE1;
use constant table => "\Q$table\E";
1HERE1
            }
            elsif($c -> {'data-type'} eq 'repository') {
                #push @classes, 'Gestinanna::DataProvider::Repository';
                my $repository = $c -> {'repository'};
                $code = "use Gestinanna::POF::Repository (\"\Q$repository\E\","
                      . "tag_classes => [qw(". join(" ", @classes). ")],"
                      . "object_classes => [qw(". join(" ", @classes). " Gestinanna::POF::Secure::Gestinanna::RepositoryObject)],"
                      . "description_classes => [qw(". join(" ", @classes). ")],"
                      . ");";
                @classes = ();
            }

            $code = "package $class;\n\n"
                  . (@classes ? ("use base qw(\n" . join("\n    ", @classes) . "\n);\n\n") : "")
                  . "$code\n\n1;";

            warn "[Defining data-provider $type]:\n$code\n";
            eval $code;

            if($@) {
                warn "Removing data-provider $type: $@\n";
                delete $config -> {'data-provider'} -> {$type};
                next;
            }
            #warn "\%INC keys: " . join("; ", keys %INC) . "\n";
            my $file = $class;
            $file =~ s{::}{/}g;
            $INC{$file . ".pm"} = 1;
            { no strict 'refs'; @{"${class}::VERSION"} = 1; }
        }
        if(UNIVERSAL::can($class, 'add_factory_types')) {
            $class -> add_factory_types($factory_class, $type);
        }
        else {
            $factory_class -> add_factory_type($type => $class);
        }
    }

    $config -> {'tag-path'} = [ $config -> {'tag-path'} ]
        unless UNIVERSAL::isa($config -> {'tag-path'}, 'ARRAY');
}

sub retrieve {
    my $class = shift;

    return Apache::ModuleConfig -> get(Apache -> request, $class);
}

sub config { return $_[0] -> {config}; }

sub resources { return $_[0] -> {resources}; }

sub make_resources {
    my $cfg = shift;
    my $prefix = shift;

    my $rs;
    foreach my $r (@{$cfg->{resource_config}->{pool}||[]}) {
        my $lb = $rs -> {$prefix . $r -> {name}} ||= ResourcePool::LoadBalancer->new(
            $prefix . $r -> {name},
            map { $_ => $r -> {$_} } grep { /^[A-Z]/ } keys %$r
        );

        if(defined $r->{dbi}) {
            require ResourcePool::Factory::DBI;
            $lb -> add_pool( ResourcePool -> new(
                ResourcePool::Factory::DBI->new(
                    $r -> {dbi} -> {datasource},
                    $r -> {dbi} -> {username},
                    $r -> {dbi} -> {password},
                    {
                        map { $_ => $r -> {dbi} -> {$_} } grep { /^[A-Z]/ } keys %{$r -> {dbi}}
                    },
                )
            ) );
        }
        elsif(defined $r->{ldap}) {
            require ResourcePool::Factory::Net::LDAP;
            my $factory = ResourcePool::Factory::Net::LDAP->new(
                $r -> {ldap} -> {hostname},
                (map { lc $_ => $r -> {ldap} -> {$_} } grep { /^[A-Z]/ } keys %{$r -> {ldap}}),
                #debug => 15,
            );
            $factory -> bind(
                $r -> {ldap} -> {dn},
                password => $r -> {ldap} -> {password},
            );
            $lb -> add_pool(ResourcePool -> new($factory));
        }
    }

    return $rs;
}

1;

__END__

=head1 NAME

Apache::Gestinanna - Apache support for Gestinanna

=head1 SYNOPSIS

In httpd.conf:

 PerlModule +AxKit
 PerlModule +Apache::Gestinanna

 <VirtualHost *>
   ServerName xxx.yyy.com
   PerlTransHandler 'sub { my $r = shift; my $uri = $r -> uri(); \
                           if($uri =~ m{\\.xml$} || $uri =~ m{/$}) { \
                               $r -> filename("/index.xml"); \
                               return Apache::Constants::OK; \
                           } \
                           return Apache::Constants::DECLINED; \
                     }'
   <Location "/">
     GestinannaConf /usr/local/etc/apache/gst.xml

     SetHandler axkit
     AxAddStyleMap text/xsl Apache::AxKit::Language::LibXSLT
     AxAddStyleMap application/x-xpathscript Apache::AxKit::Language::XPathScript

     AxContentProvider Apache::AxKit::Provider::Gestinanna

     AxHandleDirs On
  
     AxAddPlugin Apache::AxKit::Plugin::Passthru

     AxAddRootProcessor text/xsl /stylesheets/doc.xsl document
     AxAddProcessor     text/xsl /stylesheets/final.xsl

     AxGzipOutput On
   </Location>

   <Location "/stylesheets/">
     SetHandler default
   </Location>

   <Location "/images/">
     SetHandler default
   </Location>
 </VirtualHost>

In gst.xml:

 <resources
   schema="Gestinanna"
   site="1"
 >
   <pool name="dbi">
     <dbi datasource="dbi:mysql:SchemaName:localhost"
          username="username"
          password="password"
          PrintError="1"
     />
   </pool>
 </resources>

=head1 DESCRIPTION

This module manages the Apache request cycle for the Gestinanna 
Application Framework.

=head1 AUTHOR

James G. Smith, <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2003, 2004 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

