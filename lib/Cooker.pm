# $Id$
package Distribution::Cooker;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.10_01';

=head1 NAME

Distribution::Cooker - This is the description

=head1 SYNOPSIS

	use Distribution::Cooker;

=head1 DESCRIPTION

=over 4

=cut

use Cwd;
use Config::IniFiles;
use File::Spec::Functions qw(catfile);

__PACKAGE__->run( $ARGV[0] ) unless caller;

=item run( MODULE_NAME )

Calls pre-run, collects information about 

=cut

sub run
	{
	my( $class, $module ) = @_;
	
	my $self = $class->new;
	$self->init;
	
	$self->pre_run;
	
	$self->module( 
		$module || prompt( "Module name> " ) 
		);

	croak( "No module specified!" ) unless $self->module;
	
	$self->dist(
		$self->module_to_distname( $self->module )
		);
		
	$self->cook;

	$self->post_run;
	
	$self;
	}	

=item new

Create the bare object.

=cut

sub new { bless {}, $_[0] }
	
=item init

Initialize the object. 

=cut

sub init
	{
	1;
	}
	
=item pre_run

Method to call before run() starts its work. run() will
call this for you. By default this is a no-op, but you
can redefine it or override it in a subclass.

run() calls this method immediately after it creates
the object but before it initializes it.

=cut

sub pre_run  { 1 }

=item post_run

Method to call after run() ends its work. run() will
call this for you. By default this is a no-op, but you
can redefine it or override it in a subclass.

=cut

sub post_run { 1 }

=item cook

Take the templates and cook them. This version uses Template
Toolkit, but you can make a subclass to override it.

=cut

sub cook
	{
	my( $module, $dist ) = map { $_[0]->$_() } qw( module dist );
	
	mkdir $dist, 0755 or die "mkdir $dist: $!";
	chdir $dist or die "chdir $dist: $!";
	
	( my $file = $module . ".pm" ) =~ s/.*:://; 
		
	my $cwd = cwd();
	
	system 
		join " ",
		"/usr/local/bin/ttree"        ,
		"-s ~/.templates/modules"     ,
		qq|-d "$cwd"|                 ,
		"-define module='$module'"    ,
		"-define module_file='$file'" ,
		"-define module_dist='$dist'"
		;
	
	( my $base = $module ) =~ s/.*:://;
	
	rename
		catfile( 'lib', 'Foo.pm' ),
		catfile( 'lib', $file ) or die "rename: $!";
	}

=item module( [ MODULE_NAME ] )

Return the module name. With an argument, set the module name.

=cut

sub module
	{
	$_[0]->{module} = $_[1] if defined $_[1];
	$_[0]->{module};
	}

=item dist( [ DIST_NAME ] )

Return the module name. With an argument, set the module name.

=cut

sub dist
	{
	$_[0]->{dist} = $_[1] if defined $_[1];
	$_[0]->{dist};
	}

=item module_to_distname( MODULE_NAME )

Take a module name, such as C<Foo::Bar>, and turn it into
a distribution name, such as C<Foo-Bar>.

=cut

sub module_to_distname
	{
	my( $self, $module ) = @_;
	
	my $dist   = $module; $dist =~ s/::/-/g;
	my $file   = $module; $file =~ s/.*:://; $file .= ".pm";

	return $dist;	
	}

=item prompt( MESSAGE )

Show the user MESSAGE, grap a line from STDIN, and return it.

=cut
	
sub prompt
	{
	print join "\n", @_;
	print "> ";
	
	my $line = <STDIN>;
	chomp $line;
	$line;
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY


=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
