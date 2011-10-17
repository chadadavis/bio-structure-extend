#!/usr/bin/env perl

=head1 NAME

SBG::SymmExt - Symmetry extension of crystal contacts (from C3 structures)

=head1 SYNOPSIS

 use SBG::SymmExt;
 my $symmext = SBG::SymmExt->new(pdbid => $pdbid);
 my $contacts = $symmext->crystal_contacts;
 my $contact;
 $contact = $contacts->[0];
 $symmext->apply($contact);
 $symmext->undo;
 $contact = $contacts->[0];
 $symmext->apply($contact);
 $symmext->apply($contact);
 $symmext->clear_state;

=head1 DESCRIPTION

Applies crystal contact symmetries to a structur to extend the complex model

=head1 AUTHOR

Chad A Davis chad.a.davis at gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#use Devel::Comments;

use MooseX::Declare;
class SBG::SymmExt {

use strict;
use warnings;
use Moose::Autobox;
use Set::Scalar;

use SBG::SymmExt::Complex;

use SBG::U::List qw(pairs pairs2);
# For superposition()
use SBG::Superposition::Cache;
# To save domains to a file
use SBG::DomainIO::pdb;
use SBG::Run::check_ints qw(check_ints);

our $VERSION = 20111005;

has 'pdbid'    => (
    is => 'ro', isa => 'Str',
);
has 'author'   => (
    is => 'ro', isa => 'SBG::SymmExt::Complex', lazy_build => 1,
);
has 'biounit'  => (
    is => 'ro', isa => 'SBG::SymmExt::Complex', lazy_build => 1,
);

=head2 

Contacts between a biounit chain and a non-biounit chain

=cut

has 'crystal_contacts' => (
    is => 'ro', isa => 'ArrayRef',    lazy_build => 1,
);


has 'state' => (
    is => 'ro', 
    isa => 'ArrayRef', 
    lazy_build => 1,
    clearer => 'clear_state',
);


=head2 

All L<SBG::SymmExt::Complex> objects built, including the original biounit

=cut

method all {
    return [ $self->biounit, $self->state->flatten ];
}

=head2 

All L<SBG::DomainI> objects in all of the L<SBG::SymmExt::Complex> objects

=cut

method domains {
    return [ map { $_->domains->flatten } $self->all->flatten ]
}

=head2 

Given a crystal contact, apply its superposition to the last state added,
creating a new copy of the last sub-complex added.

=cut

method apply ($contact) {
    die unless $contact;
    ### $contact
    my $last = $self->state->last || $self->biounit;
    my $clone = $last->clone;
    my $transformation = $self->superposition($contact)->transformation;
    for my $domain ($clone->domains->flatten) {
        # Apply the crystal contact transformation first (hence on the right),
        # then the existing transformation already in the model.
        my $rl = $domain->transformation x $transformation;
        # And assign this as the new transformation
        $domain->transformation($rl);
    }
    $self->state->push($clone);
    return $self;
}

=head2

Superposition corresponding to a crystal contact. Direction is from the chain
of the biounit structure onto the chain of the author-deposited structure.

=cut

method superposition ($contact) {
    ### $contact
    my ($chain_b, $chain_a) = @$contact;
    my $doms = [
        $self->biounit->domain->at($chain_b), 
        $self->author->domain->at($chain_a),
    ];
    # Biounit chain onto author chain
    my $superposition = SBG::Superposition::Cache::superposition(@$doms);
    return $superposition;
}

method undo {
    return $self->state->pop;
}

=head2 

Write current model to given PDB filename. Creates a temp file otherwise. You can get it's name with:

 my $io = $symmext->write();
 print $io->file;

=cut

method write ($file) {
    my $io = SBG::DomainIO::pdb->new(file => ">$file");
    $io->write($self->domains->flatten);
    return $io;
}

method _build_state {
    return [];
}

method _build_author {
    return SBG::SymmExt::Complex->new(pdbid => $self->pdbid, );
}

method _build_biounit {
    return SBG::SymmExt::Complex->new(pdbid => $self->pdbid, assembly => 1, );
}


# Pairs of potential interactions, biounit to non-biounit
method _pairs {
    my $set_a = Set::Scalar->new($self->author->chains->flatten);
    my $set_b = Set::Scalar->new($self->biounit->chains->flatten);
    # What's in the author structure, but not in biounit
    my $set_d = $set_a->difference($set_b);

    my $contacts = [];

    # All pairs between a biounit chain an a non-biounit chain
    my @pairs = pairs2($self->biounit->chains, [ $set_d->members ]);
    return wantarray ? @pairs : \@pairs;
}

method _build_crystal_contacts {
    my $contacts = [];
    for my $pair ($self->_pairs()) {
        my @doms = map { 
            SBG::Domain->new(pdbid => $self->pdbid, descriptor => "CHAIN $_");
        } @$pair;
        my $res_contacts = check_ints(\@doms);
        if ($res_contacts) { $contacts->push($pair); }
    }
    return $contacts;
}

} # class
