#!/usr/bin/env perl
package Test::SBG::SymmExt::Complex;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Moose::Autobox;
use Data::Show;

# If executed directly, as a script, rather than a loaded module
if (! caller) {
    Test::Class->runtests();
}

sub startup : Tests(startup => 1) {
    use_ok 'SBG::SymmExt::Complex' or die;
}

sub setup : Test(setup => 1) {
    my ($self) = @_;
    my $obj = new_ok('SBG::SymmExt::Complex' => [ 
        pdbid => '1hg4', assembly => 1,
    ]);
    $self->{obj} = $obj;
}


sub domain : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    is $obj->domain->keys->length, 3, 'domain keys' or show $obj;
}

sub author : Tests {
    # Create our own domain, using author-deposited structure (no assembly)
    my $obj = new_ok('SBG::SymmExt::Complex' => [ 
        pdbid => '1hg4',
    ]);
    is $obj->domain->keys->length, 6, 'domain keys' or show $obj;

}


1;
