package Apache::Gestinanna;

use Apache::ModuleConfig;
use ResourcePool;
use ResourcePool::LoadBalancer;
use DBI;

use Gestinanna::POF;
use Gestinanna::Schema;
use Gestinanna::SiteConfiguration;

use Apache::AxKit::Provider::Gestinanna;

our $VERSION = '0.03';

use XML::Simple;

use strict;

if($ENV{MOD_PERL}) {
    if($mod_perl::VERSION < 1.99) {  
        our @ISA = qw(DynaLoader);
        __PACKAGE__ -> bootstrap($VERSION);
    }
}

sub new {
    my $class = shift;

    $class = ref $class || $class;
    return bless { } => $class;
}

sub request {
    return Apache::Gestinanna::Request -> new;
}

sub GestinannaSite ($$$) {
    my($cfg, $param, $site) = @_;

    @{$cfg}{qw(resource schema site)} = split(/:/, $site);

    warn "resouce:schena:site :: $$cfg{resource} : $$cfg{schema} : $$cfg{site}\n";
    if($cfg -> {files}) {
        read_config($cfg, $cfg->{files}->[0]);

        Apache -> push_handlers(PerlChildInitHandler => sub {
            $cfg -> {resources} = $cfg -> make_resources;
        });
    }

    # Would love to be able to automatically add the following to the config
#     SetHandler axkit

#     AxContentProvider Apache::AxKit::Provider::Gestinanna
#     AxStyleProvider   Apache::AxKit::Provider::Gestinanna
#     AxAddDynamicProcessor Apache::Gestinanna::AxKitStyleProvider

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

    warn "GestinannaConf: Only parsing first file ($files[0])\n" if @files > 1;
    $cfg -> {files} = \@files;
}

sub read_resource_config {
    my($cfg, $file) = @_;

    my $xs = new XML::Simple(
        ContentKey => '-content',
        ForceArray => [qw(
            pool
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


    $cfg -> {resource_config} = $xs -> XMLin($file);
}

sub read_config {
    my($cfg, $file) = @_;

    $cfg -> read_resource_config($file);

    #my ($schema, $site) = delete @{$cfg -> {resource_config}}{qw(schema site)};
    my ($resource, $schema, $site) = @{$cfg}{qw(resource schema site)};

    #$cfg -> {prefork_resources} = $cfg -> make_resources('prefork_');

    # load configuration from database
    #my $dbh = $cfg -> {prefork_resources} -> {prefork_dbi} -> get();
    my $dbh;
    foreach my $r (@{$cfg->{resource_config}->{pool}||[]}) {
        if(defined $r->{dbi} && $r -> {name} eq $resource) {
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
        elsif(defined $r -> {alzabo} && $r -> {name} eq $resource) {   
            eval { $dbh = DBI->connect(
                $r -> {alzabo} -> {datasource},
                $r -> {alzabo} -> {username},
                $r -> {alzabo} -> {password},
                {
                    map { $_ => $r -> {alzabo} -> {$_} } grep { /^[A-Z]/ } keys %{$r -> {alzabo}}
                },
            ); };
            $schema = $r -> {alzabo} -> {schema};
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

    my $site_cfg = get_site_config($alzabo_schema, $site);

    $site_cfg -> build_factory;

#    my $site_data = $alzabo_schema -> table('Site') -> row_by_pk( pk => $site );
#    my $config = $cfg -> parse_site_config($site_data);

    #my $config = $cfg -> parse_site_config($site_data -> select('configuration') || "<configuration/>");

    $dbh -> disconnect;

    $cfg -> {config} = $site_cfg;
    $cfg -> {schema} = $schema;
    $cfg -> {site} = $site;
}

sub get_site_config {
    my($schema, $site) = @_;

    my $site_data = $schema -> table('Site') -> row_by_pk( pk => $site );
    if($site_data) {
        my $parent_site = $site_data -> parent_site;

        my $parent;
        if($parent_site) {
            $parent = get_site_config($schema, $parent_site);
        }

        my $s = Gestinanna::SiteConfiguration -> new(parent => $parent, site => $site);
        $s -> parse_config($site_data -> configuration);
        return $s;
    }
    return Gestinanna::SiteConfiguration -> new(site => $site);
}

sub parse_site_config {
    my($self, $site_data) = @_;

    my $parent_site = $site_data -> parent_site;
    my $site;

    if($parent_site) {
        my $parent_data = $site_data -> table -> row_by_pk( pk => $parent_site );
        my $parent = $self -> parse_site_config($parent_data);
        $site = Gestinanna::SiteConfiguration -> new( parent => $parent, site => $site_data -> site );
    }
    else {
        $site = Gestinanna::SiteConfiguration -> new( );
    }
    $site -> parse_config( $site_data -> select('configuration') );

    # need to handle building the factory...
    return $site;

    # pre-load classes
    my $config = { };
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
                $code = <<EOF;
use constant table => "\Q$table\E";
EOF
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

    return $config;
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
        elsif(defined $r->{alzabo}) {
            require ResourcePool::Factory::Alzabo;
            $lb -> add_pool( ResourcePool -> new(
                ResourcePool::Factory::Alzabo->new(
                    $r -> {alzabo} -> {schema},
                    $r -> {alzabo} -> {datasource},
                    $r -> {alzabo} -> {username},
                    $r -> {alzabo} -> {password},
                    {
                        map { $_ => $r -> {alzabo} -> {$_} } grep { /^[A-Z]/ } keys %{$r -> {alzabo}}
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
   <Location "/">
     GestinannaConf etc/apache/gst.xml
     GestinannaSite dbi:Gestinanna:1

     SetHandler axkit
     AxAddStyleMap text/xsl Apache::AxKit::Language::LibXSLT
     AxAddStyleMap application/x-xpathscript Apache::AxKit::Language::XPathScript

     AxContentProvider Apache::AxKit::Provider::Gestinanna
     AxStyleProvider   Apache::AxKit::Provider::Gestinanna
     
     AxAddProcessor     text/xsl xslt:/theme/_default/final
     #TODO: AxAddDynamicProcessor Apache::Gestinanna::AxKitStyleProvider

     AxHandleDirs On
  

     AxGzipOutput On
   </Location>

   <Location "/images/">
     SetHandler default
   </Location>
 </VirtualHost>

In gst.xml:

 <resources>
   <pool name="dbi">
     <alzabo datasource="dbi:mysql:SchemaName:localhost"
          schema="SchemaName"
          username="username"
          password="password"
          PrintError="1"
     />
   </pool>
 </resources>

=head1 DESCRIPTION

This module manages the Apache request cycle for the Gestinanna 
Application Framework.

=head1 Apache Directives

=head2 GestinannaConf file

This designates the file from which the resource configuration is 
taken.  Each resource pool is named and consists of one or more 
configurations that should point to the same resource (but perhaps on 
different hosts).

=head2 GestinannaSite  pool_name:schema:site_number

This designates the site that is being served by the current 
configuration.  This is a triplet consisting of the name of the 
resource pool (which should be a DBI connection), the schema name (or 
database name), and the site number.

This allows multiple sites to share the same resource configuration.

=head1 AUTHOR

James G. Smith, <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2003, 2004 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

