package Apache::Gestinanna;

#$Id: Makefile.PL,v 1.1 2004/02/23 21:53:55 jgsmith Exp $

use ExtUtils::MakeMaker;

use Apache::ExtUtils qw: command_table :;
use Apache::src ();

#
# setup test stuff
#

eval {
    require Apache::Test;
    require Apache::TestMM;
    Apache::TestMM -> import(qw(test clean));
};

my @scripts;

if($@) {
    warn <<1HERE1

Apache::Test is not installed.  You will need to re-run
`perl Makefile.PL' after installing Apache::Test in order 
to run any significant tests.

1HERE1

}
else {

    # if we have Apache::Test, we need this to actually run tests
    $other_prereqs{'DBD::SQLite'} = 0;  

    @scripts = qw(t/TEST t/SMOKE);

    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script($_) for @scripts;
}

###
### write makefile
###

my @directives = (
     { name         => 'GestinannaConf',
       errmsg       => 'name of Gestinanna configuration file',
       args_how     => 'RAW_ARGS',
       req_override => 'ACCESS_CONF',
     },
);

command_table(\@directives);

my $file = __PACKAGE__;
$file =~ s{::}{/}g;

WriteMakefile(
  NAME         => __PACKAGE__,
  VERSION_FROM => 'lib/'.$file.'.pm',
  INC          => Apache::src->new->inc,
  AUTHOR       => 'James Smith <jsmith@cpan.org>',
  ABSTRACT_FROM => 'lib/'.$file.'.pm',
  PREREQ_PM    => { 
                    Apache::Session => 0,
                    Apache::Test => 1.00,
                    AxKit => 1.61,
                    Gestinanna => 0,
                    Gestinanna::POF => 0,
                    ResourcePool => 1.01,
                    ResourcePool::Factory::DBI => 1.01,
                    XML::Simple => 0,
                    XML::XPath => 1.13,
		    mod_perl => 1.24,
                    %other_prereqs,
		  },
);
