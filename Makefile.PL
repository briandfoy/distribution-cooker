# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Distribution::Cooker',
	'ABSTRACT'     => 'Create a module directory from your own templates',
	'VERSION_FROM' => 'lib/Cooker.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'       => '0',
		'Config::IniFiles' => '0',
		'Template'         => '0',
		},

	'PM'           => {
		'lib/Cooker.pm'         => '$(INST_LIBDIR)/Cooker.pm',
		},
		
	'EXE_FILES' => [ 'script/dist_cooker' ],
		
	'DIR' => [], # do not look in templates for Makefile.PL

	'MAN3PODS'     => {
		'lib/Cooker.pm' => '$(INST_MAN3DIR)/Distribution::Cooker.3',
		},

	clean  => { FILES    => q|Distribution-Cooker-*| },

	(eval { ExtUtils::MakeMaker->VERSION(6.46) }
		? (META_MERGE => {
			resources => {
				Repository => 'http://github.com/briandfoy/distribution--cooker/'
				}
			})
		: ()
	),

	);
