#!/usr/bin/env perl
package Test::SBG::SymmExt;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Moose::Autobox;
use Data::Show;

#use Devel::Comments;

# If executed directly, as a script, rather than a loaded module
if (! caller) {
    Test::Class->runtests();
}

sub startup : Tests(startup => 1) {
    use_ok 'SBG::SymmExt' or die;
}

sub setup : Test(setup => 1) {
    my ($self) = @_;
    my $obj = new_ok('SBG::SymmExt' => [ pdbid => '1hg4' ]);
    $self->{obj} = $obj;
}

sub contacts : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    my $contacts = $obj->contacts;
    is $contacts->length, 16, 'contacts() from trans_db' 
        or diag show $contacts;

}

sub author : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    is $obj->biounit->domain->keys->length, 3;
}

sub biounit : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    is $obj->author->domain->keys->length, 6;
}

sub graph : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    # Interaction in the DB have direction, but this graph is undirected
    # Half as many
    is scalar($obj->graph->edges), 16/2 or diag show $obj->contacts;
}

sub crystal_contacts : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    my $contacts = $obj->crystal_contacts;
    is $contacts->length, 2 
        or diag show $contacts;

    # Verify the actual contacts
    my $flattened = [ sort map { "@$_" } @$contacts ];
    eq_array $flattened, [ 'C B', 'D B' ]
        or diag show $contacts;
}

sub superposition : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    my $contacts = $obj->crystal_contacts;
    my $contact = $contacts->[0];
    my $superposition = $obj->superposition($contact);
    isa_ok $superposition, 'SBG::Superposition' 
        or diag show $superposition;
    cmp_ok $superposition->scores->at('Sc'), '>', 2.0
        or diag show $superposition;
}

sub default_state : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    is_deeply $obj->state, [] 
        or diag show $obj->state;
}

sub default_all : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    is_deeply $obj->all, [ $obj->biounit ] 
        or diag show $obj->all;
}

sub apply : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    $obj->apply($obj->crystal_contacts->first);
    is $obj->state->length, 1 
        or diag show $obj->state;
}

sub undo : Tests {
    my ($self) = @_;
    $self->apply;
    my $obj = $self->{obj};
    is $obj->state->length, 1 
        or show diag $obj->state;
    $obj->undo;
    is $obj->state->length, 0 
        or show diag $obj->state;

}

sub domains : Tests {
    my ($self) = @_;
    $self->apply;
    my $obj = $self->{obj};
    is $obj->domains->length, 6
        or diag show $obj;
}

sub qcons_contacts : Tests {
    my ($self) = @_;
    my $obj = $self->{obj};
    my $contacts = $obj->qcons_contacts;
    is $contacts->length, 2
        or diag show $obj;
    # Verify the actual contacts
    my $flattened = [ sort map { "@$_" } @$contacts ];
    eq_array $flattened, [ 'C B', 'D B' ]
        or diag show $contacts;
}

1;
