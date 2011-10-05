#!/usr/bin/env perl

=head1 SYNOPSIS


=head1 DESCRIPTION



=cut

#use Devel::Comments;

use MooseX::Declare;
class SBG::SymmExt {

use strict;
use warnings;
use Moose::Autobox;
use Graph::Undirected;
use Set::Scalar;
use DBI;

use SBG::SymmExt::Complex;

use SBG::U::List qw(pairs2);
# For superposition()
use SBG::Superposition::Cache;
# To save domains to a file
use SBG::DomainIO::pdb;


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

Contacts between all chain in the author-deposited structure

=cut

has 'contacts' => (
    is => 'ro', isa => 'ArrayRef[ArrayRef]',    lazy_build => 1,
);

=head2 

Contacts between a biounit chain and a non-biounit chain

=cut

has 'crystal_contacts' => (
    is => 'ro', isa => 'ArrayRef[ArrayRef]',    lazy_build => 1,
);

has 'contacts_db'   => (
    is => 'rw', isa => 'Str', default => 'trans_3_0',
);

has 'graph' => (
    is => 'ro', isa => 'Graph::Undirected', lazy_build => 1,
);

has 'state' => (
    is => 'ro', 
    isa => 'ArrayRef', 
    lazy_build => 1,
    clearer => 'clear_state',
);

has '_contacts_sql' => ( is => 'ro', isa => 'Str', default => <<EOF);
SELECT e1.chain as chain1, e2.chain as chain2
FROM 
     entity  as e1 
join contact as c1 on (e1.id=c1.id_entity1)
join entity  as e2 on (e2.id=c1.id_entity2)
where 
    e1.idcode=? and e1.type='chain' -- restrict to 'chain'  for speedup
and e2.idcode=? and e2.type='chain' -- restrict both halves for speedup
;
EOF


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

method _build_graph {
    my $graph = Graph::Undirected->new;
    for my $contact ($self->contacts->flatten) {
        $graph->add_edge(@$contact);
    }
    return $graph;
}

method _build_contacts {
    my $pdbid = $self->pdbid;
    my $dsn = 'dbi:mysql:host=russelllab.org;database=' . $self->contacts_db;
    # Cached
    my $dbh = DBI->connect_cached($dsn, 'anonymous');
    # Also cached
    my $sth = $dbh->prepare_cached($self->_contacts_sql);
    $sth->execute($pdbid, $pdbid);
    my $rs = $sth->fetchall_arrayref;
    return $rs;
}

method _build_crystal_contacts {
    my $set_a = Set::Scalar->new($self->author->chains->flatten);
    my $set_b = Set::Scalar->new($self->biounit->chains->flatten);
    # What's in the author structure, but not in biounit
    my $set_d = $set_a->difference($set_b);

    my $contacts = [];

    # All pairs between a biounit chain an a non-biounit chain
    for my $pair (pairs2($self->biounit->chains, [ $set_d->members ])) {
        my ($chain_b, $chain_a) = @$pair;
        # Skip, if this pair is not in contact (Note, undirected graph)
        if (! $self->graph->has_edge($chain_b, $chain_a)) { next; }
        $contacts->push($pair);
    }
    return $contacts;
}


} # class
