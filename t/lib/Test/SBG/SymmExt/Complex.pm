#!/usr/bin/env perl
package Test::SBG::SymmExt::Complex;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Moose::Autobox;
use Data::Show;
use PDL;

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

sub transform : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    my $matrix = pdl [ 
        [ 1, 0, 0, 0, ],
        [ 0, 2, 0, 0, ],
        [ 1, 0, 3, 0, ],
        [ 1, 0, 0, 1, ],
    ];
    $obj->transform($matrix);
    ok all approx($obj->domains->first->transformation->matrix, $matrix);
}

1;
