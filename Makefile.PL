# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.14";

WriteMakefile(
	'NAME'	       => 'Distribution::Cooker',
	'ABSTRACT'     => 'This is what the module does',
	'VERSION_FROM' => 'lib/Cooker.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'       => '0',
		'Config::IniFiles' => '0',
		},

	'PM'           => {
		'lib/Cooker.pm'         => '$(INST_LIBDIR)/Cooker.pm',
		},

	'MAN3PODS'     => {
		'lib/Cooker.pm' => '$(INST_MAN3DIR)/Distribution::Cooker.3',
		},

	clean  => { FILES    => q|Distribution-Cooker-*| },

	);
