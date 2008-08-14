#!/usr/bin/perl

use Test::More 'no_plan';

my $class  = 'Distribution::Cooker';
my $module = 'Foo::Bar';
my $dist   = 'Foo-Bar';

use_ok( $class );
can_ok( $class, qw(pre_run run post_run) );

my $cooker = $class->new;
isa_ok( $cooker, $class );
can_ok( $cooker, qw(pre_run run post_run) );

ok( $cooker->pre_run,  "pre_run is no_op and returns true"  );
ok( $cooker->post_run, "post_run is no_op and returns true" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# mock the cook method so we don't do anything
{
no strict 'refs';
no warnings 'redefine';
local *{"${class}::cook"} = sub { 'Buster' };
is( $class->cook, 'Buster', "cook has been mocked" );

# try it with a module name
{
ok( my $cooker = $class->run( $module ), "run returns something that is true" );
isa_ok( $cooker, $class );

is( $cooker->module, $module, "Set module to $module" );
is( $cooker->dist, $dist, "Set module to $dist" );
}

# try it with prompting
{
my $module = 'Baz::Quux';
my $dist   = 'Baz-Quux';

local *{"${class}::prompt"} = sub { $module };
is( $class->prompt, $module, "prompt has been mocked" );

ok( my $cooker = $class->run, "run returns something that is true" );
isa_ok( $cooker, $class );

is( $cooker->module, $module, "Set module to $module" );
is( $cooker->dist, $dist, "Set module to $dist" );
}

# try it with no module name
{
my $module = 'Baz::Quux';
my $dist   = 'Baz-Quux';

local *{"${class}::prompt"} = sub { return };
is( $class->prompt, undef, "prompt has been mocked as undef" );

my $rc = eval { $class->run };
my $at = $@;
ok( defined $at, "eval failed for run() with no module name" );
}

}