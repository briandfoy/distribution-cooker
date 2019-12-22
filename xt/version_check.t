#!perl
use v5.26;

#use Module::Extract::DeclaredPerlVersion;
use Mojo::Util qw(dumper);
use Perl::Version;
use Test::More 1;

diag( <<~"HERE" );
	Module:   @{[ module_minimum()   ]}
	Makefile: @{[ makefile_minimum() ]}
	Travis:   @{[ travis_minimum()   ]}
	HERE

ok( makefile_minimum() == module_minimum(), "Makefile version matches module version" )
	or diag( "Makefile: @{[makefile_minimum()]} Module: @{[module_minimum()]}" );

ok( travis_minimum() == module_minimum(), "Travis version matches module version" )
	or diag( "Travis: @{[travis_minimum()]} Module: @{[module_minimum()]}" );

done_testing();

# Get the declared versions from the modules
sub module_minimum {
	state $ff = require File::Find;
	state $rc = require Module::Extract::DeclaredMinimumPerl;
	state $min_version = undef;

	return $min_version if defined $min_version;

	my @pm_files = ();
	my $wanted = sub {
		push @pm_files, $File::Find::name if $File::Find::name =~ /\.pm\z/;
		};
	File::Find::find( $wanted, 'lib' );

	my $extor = Module::Extract::DeclaredMinimumPerl->new;

	( $min_version ) =
		map { $_->[1] }
		sort { $a->[1] <=> $b->[1] }
		map { [ $_, $extor->get_minimum_declared_perl( $_ )->numify ] }
		@pm_files;

	return $min_version // '5.008';
	}

# Get the declared version from the Makefile.PL
sub makefile_minimum {
	state $min_version = undef;

	return $min_version if defined $min_version;

	delete $INC{'./Makefile.PL'};
	my $package = require './Makefile.PL';
	my $makefile_args = $package->arguments;
	my $declared = $makefile_args->{MIN_PERL_VERSION};
	$min_version = Perl::Version->new( $declared // '5.008' );

	return $min_version;
	}

# Get the versions from .travis.yml
sub travis_minimum {
	state $rc = require Mojo::File;
	state $yy = require YAML::XS;
	state $min_version = undef;

	return $min_version if defined $min_version;

	my $file = Mojo::File->new( '.travis.yml' );
	my $yaml = $file->slurp;
	my $perl = YAML::XS::Load( $yaml );

	( $min_version ) =
		sort { $a <=> $b }
		map { Perl::Version->new($_)->numify }
		$perl->{perl}->@*;

	return $min_version;
	}
