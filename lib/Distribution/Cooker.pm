use utf8;

package Distribution::Cooker;
use v5.20;
use experimental qw(signatures);

use subs qw();
use vars qw($VERSION);


$VERSION = '2.001';

=encoding utf8

=head1 NAME

Distribution::Cooker - Create a module directory from your own templates

=head1 SYNOPSIS

	use Distribution::Cooker;

	Distribution::Cooker->run( ... );

	# most of this should go through the dist_cooker sketch

=head1 DESCRIPTION

=over 4

=cut

use Carp                  qw(croak carp);
use Cwd;
use Config::IniFiles;
use File::Find;
use File::Basename        qw(dirname);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile abs2rel);
use Mojo::File;
use Mojo::Template;
use Mojo::Util            qw(decode encode);

__PACKAGE__->run( @ARGV ) unless caller;

=item run( [ MODULE_NAME, [ DESCRIPTION ] ] )

Calls pre-run, collects information about the module you want to
create, cooks the templates, and calls post-run.

If you don't specify the module name, it prompts you. If you don't
specify a description, it prompts you.

=cut

sub run {
	my( $class, $module, $description, $repo_name ) = @_;

	my $self = $class->new;
	$self->init;

	$self->pre_run;

	$self->module( $module || prompt( "Module name" ) );
	croak( "No module specified!\n" ) unless $self->module;
	croak( "Illegal module name [$module]\n" )
		unless $self->module =~ m/ \A [A-Za-z0-9_]+ ( :: [A-Za-z0-9_]+ )* \z /x;
	$self->description( $description || prompt( "Description" ) );

	$self->repo_name( $repo_name || prompt( "Repo name" ) );

	$self->dist( $self->module_to_distname( $self->module ) );

	$self->cook;

	$self->post_run;

	$self;
	}

=item new

Create the bare object. There's nothing fancy here, but if you need
something more powerful you can create a subclass.

=cut

# There's got to be a better way to deal with the config
sub new {
	my $file = catfile( $ENV{HOME}, '.dist_cookerrc' );
	my $config;
	my( $name, $email ) = ( 'Frank Serpico', 'serpico@example.com' );

	if( -e $file ) {
		require Config::IniFiles;
		$config = Config::IniFiles->new( -file => $file );
		$name  = $config->val( 'user', 'name' );
		$email = $config->val( 'user', 'email' );
		}

	bless {
		name  => $name,
		email => $email,
		}, $_[0]
	}

=item init

Initialize the object. There's nothing fancy here, but if you need
something more powerful you can create a subclass.

=cut

sub init { 1 }

=item pre_run

Method to call before run() starts its work. run() will call this for
you. By default this is a no-op, but you can redefine it or override
it in a subclass.

run() calls this method immediately after it creates the object but
before it initializes it.

=cut

sub pre_run  { 1 }

=item post_run

Method to call after C<run()> ends its work. C<run()> calls this for
you. By default this is a no-op, but you can redefine it or override
it in a subclass.

=cut

sub post_run { 1 }

=item cook

Take the templates and cook them. This version uses Template
Toolkit, but you can make a subclass to override it.

I assume my own favorite values, and haven't made these
customizable yet.

=over 4

=item Your distribution template directory is F<~/.templates/dist_cooker>

=item Your module template name is F<lib/Foo.pm>

=back

When C<cook> processes the templates, it provides definitions for
these template variables:

=over 4

=item description => the module description

=item module      => the package name (Foo::Bar)

=item module_dist => the distribution name (Foo-Bar)

=item module_file => module file name (Bar.pm)

=item module_path => module path under lib/ (Foo/Bar.pm)

=item repo_name   => lowercase module with hyphens (foo-bar)

=item year        => the current year

=back

While processing the templates, C<cook> ignores F<.git>, F<.svn>, and
F<CVS> directories.

=cut

sub cook {
	my $self = shift;

	my $dir = lc $self->dist;

	make_path( $dir ) or croak "mkdir $dir: $!";
	chdir $dir        or croak "chdir $dir: $!";

	my $cwd = cwd();

	my $files = $self->get_template_files;

	my $old = catfile( 'lib', $self->module_template_basename );
	my $new = catfile( 'lib', $self->module_path );

	my $vars = $self->template_vars;

	my $mt = Mojo::Template->new->line_start('ϕ')->tag_start('«')->tag_end('»');
	foreach my $file ( $files->@* ) {
		my $new_file = abs2rel( $file, $self->distribution_template_dir );

		if( -d $file ) {
			make_path( $new_file );
			next;
			}

		my $contents = decode( 'UTF-8', Mojo::File->new( $file )->slurp );
		my $rendered = $mt->vars(1)->render( $contents, $vars );
		Mojo::File->new( $new_file )->spurt( encode( 'UTF-8', $rendered ) );
		}

	make_path dirname($new);
	rename $old => $new
		or croak "Could not rename [$old] to [$new]: $!";
	}

sub get_template_files ( $self ) {
	my $template_dir = $self->distribution_template_dir;

	my @files;
	my $wanted = sub {
		if( /\A(\.git|\.svn|CVS|\.infra)\b/ ) {
			$File::Find::prune = 1;
			return;
			}
		push @files, $File::Find::name;
		};

	find( $wanted, $self->distribution_template_dir );

	return \@files;
	}

=item template_vars

=cut

sub template_vars {
	my( $self ) = @_;
	state $hash = {
		cwd         => cwd(),
		description => $self->description,
		dir         => catfile( 'lib', dirname( $self->module_path ) ),
		dist        => $self->dist,
		email       => $self->{email},
		module_path => $self->module_path,
		name        => $self->{name},
		path        => $self->module_path,
		repo_name   => $self->repo_name,
		year        => ( localtime )[5] + 1900,
		module      => $self->module,
		};

	$hash;
	}

sub _src_to_dest {
	state $mt = Mojo::Template->var(1);

	my( $self, $source, $base, $dest ) = @_;
		say "File source: $source";

	my $rendered = $mt->render_file( $base, $self->template_vars );

		say "File dest: $dest";

	}

=item distribution_template_dir

Returns the name of the directory that contains the distribution
templates.

The default path is F<~/.templates/modules>. You can override this in
a subclass.

=cut

sub distribution_template_dir {
	my $path = catfile( $ENV{HOME}, '.templates', 'modules' );
	$path = readlink($path) if -l $path;

	croak "Couldn't find templates at $path!\n" unless -d $path;

	$path;
	}

=item description

Returns the description of the module.

The default name is C<TODO: describe this module>. You can override
this in a subclass.

=cut

sub description {
	$_[0]->{description} = $_[1] if defined $_[1];
	$_[0]->{description} || 'TODO: describe this module'
	}

=item repo_name

Returns the repo_name for the project. This defaults to the module
name all lowercased with C<::> replaced with C<->. You can override
this in a subclass.

=cut

sub repo_name {
	$_[0]->{repo_name} = $_[1] if defined $_[1];
	$_[0]->{repo_name} // $_[0]->module =~ s/::/-/gr
	}

=item module_template_basename

Returns the name of the file that is the module.

The default name is F<Foo.pm>. You can override this in a subclass.

=cut

sub module_template_basename {
	"Foo.pm";
	}

=item module( [ MODULE_NAME ] )

Return the module name. With an argument, set the module name.

=cut

sub module {
	$_[0]->{module} = $_[1] if defined $_[1];
	$_[0]->{module};
	}

=item module_path()

Return the module path under F<lib/>. You must have set C<module>
already.

=cut

sub module_path {
	my @parts = split /::/, $_[0]->{module};
	return unless @parts;
	$parts[-1] .= '.pm';
	my $path = catfile( @parts );
	}

=item dist( [ DIST_NAME ] )

Return the dist name. With an argument, set the module name.

=cut

sub dist {
	$_[0]->{dist} = $_[1] if defined $_[1];
	$_[0]->{dist};
	}

=item module_to_distname( MODULE_NAME )

Take a module name, such as C<Foo::Bar>, and turn it into a
distribution name, such as C<Foo-Bar>.

=cut

sub module_to_distname {
	my( $self, $module ) = @_;

	my $dist   = $module; $dist =~ s/::/-/g;
	my $file   = $module; $file =~ s/.*:://; $file .= ".pm";

	return $dist;
	}

=item prompt( MESSAGE )

Show the user MESSAGE, grap a line from STDIN, and return it.

=cut

sub prompt {
	print join "\n", @_;
	print "> ";

	my $line = <STDIN>;
	chomp $line;
	$line;
	}

=back

=head1 TO DO

Right now, C<Distribution::Cooker> uses the defaults that I like, but
that should come from a configuration file.

=head1 SEE ALSO

Other modules, such as C<Module:Starter>, do a similar job but don't
give you as much flexibility with your templates.

=head1 SOURCE AVAILABILITY

This module is in Github:

	http://github.com/briandfoy/distribution-cooker/

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
