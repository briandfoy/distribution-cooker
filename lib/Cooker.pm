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
	$_[0]->pre_run;
	
	my $module = shift || prompt( "Module name> " );

	my $dist   = $_[0]->module_to_distname( $module )
	
	my $cwd    = catfile( cwd(), $dist );
	
	$self->cook;

	$_[0]->post_run;
	
	1;
	}	

=item pre_run

Method to call before run() starts its work. run() will
call this for you. By default this is a no-op, but you
can redefine it or override it in a subclass.

=cut

sub pre_run  { 1 }

=item pre_run

Method to call before run() starts its work. run() will
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
	my $self = shift;
	
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
		catfile( $dist, 'lib', 'Foo.pm' ),
		catfile( $dist, 'lib', $file );
	}

=item

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
