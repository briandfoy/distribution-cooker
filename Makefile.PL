require 5.008;
use strict;
use warnings;

my $github    = 'https://github.com/briandfoy/';
my $main_file = 'lib/Distribution/Cooker.pm';

my %WriteMakefile = (
	'NAME'	        => 'Distribution::Cooker',
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'       => '0.94',
		'Config::IniFiles' => '0',
		'Template'         => '0',
		},

	'EXE_FILES' => [ 'script/dist_cooker' ],
		
	'DIR' => [], # do not look in templates for Makefile.PL

	clean  => { FILES    => q|Distribution-Cooker-*| },

	META_MERGE => {
		resources => {
			Repository => 'http://github.com/briandfoy/distribution-cooker/'
			}
		},

	);

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			//
		"$MM 6.64";
	eval "use $MM_version";
	eval "use Test::Manifest 1.21" 
		if -e File::Spec->catfile( qw(t test_manifest) );
	WriteMakefile( %WriteMakefile );
	}


no warnings;
__PACKAGE__;
