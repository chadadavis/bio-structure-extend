#!/usr/bin/env perl

=head1 NAME

symmext - Take a trimer and use a crystal contact to generate 5-fold symmetry

=head1 SYNOPSIS



=head1 DESCRIPTION

Assumes that each PDB ID is exactly a 3-mer in the biounit and at least a
4-mer in the PDB deposited structure, also that the deposited structure is
homo-meric.

Requires that the chain IDs are the same between the author-depoisited
structure and the biounit assembly.

=cut

use strict;
use warnings;

use Devel::Comments;
use Bio::Structure::IO;
use Bio::Tools::Run::QCons;
use Graph::Undirected;

use SBG::Domain;
use SBG::Superposition::Cache qw(superposition);
use SBG::Run::rasmol qw(rasmol);
use SBG::U::List qw(pairs pairs2);
#use SBG::Run::qcons qw(qcons);

use FindBin qw/$Bin/;
use lib "$Bin/../lib/";
use SBG::SymmExt qw(assembly2doms);

use SBG::U::DB qw(connect dsn);

my $sql = <<'EOF';
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


for my $pdbid (@ARGV) {
    # Use first assembly of biounit by default
    my $assembly = SBG::Domain->new(pdbid => $pdbid, assembly => 1);

    # Reading doms and indexing by chain belongs in BioX::Structure::Complex
    my @assembly_doms = assembly2doms($assembly);
    my %assembly_dom = map { $_->onechain => $_ } @assembly_doms;
    my @assembly_chains = keys %assembly_dom;
    ### @assembly_chains

    # Get author domains
    # Index by chain ID
    my $author = SBG::Domain->new(pdbid => $pdbid);
    my @author_doms = assembly2doms($author);
    my %author_dom = map { $_->onechain => $_ } @author_doms;
    my @author_chains = keys %author_dom;
    ### @author_chains

    # Components that are only in the author structure (set difference)
    my @diff_chains = grep { 
        my $a = $_; 
        # True when this author chain equals none of the assembly chains
        @assembly_chains == grep { $a ne $_ } @assembly_chains 
    } @author_chains;
    ### @diff_chains

    # Track all contacts in an undirected graph
    my $graph = Graph::Undirected->new;
    my $contacts = contacts($pdbid);
    for my $contact (@$contacts) {
        $graph->add_edge(@$contact);
    }

    # Enumerate contacts, but only potential crystal contacts
    # I.e. an interactions between one biounit asssembly component and one not
    for my $pair (pairs2(\@assembly_chains, \@diff_chains)) {
        my ($assembly_chain, $author_chain) = @$pair;

        # Skip, if this pair is not in contact (Note, undirected graph)
        if (! $graph->has_edge($assembly_chain, $author_chain)) { next; }
        ### Crystal contact: $assembly_chain, $author_chain

        # Interactive keep/reject prompt at each step in tree search?
        # TODO how to iterate here?

        # Get superposition over crystal contact
        my $superposition = superposition(
            $assembly_dom{$assembly_chain}, $author_dom{$author_chain},
        );
        my @copies = map { $_->clone } @assembly_doms;
        #    $superposition->apply(@copies); # broken
        $superposition->apply($_) for @copies;

        # Display them together
        # (visually verify whether overlap is a superposition or a clash)
        rasmol(@assembly_doms, @copies);
    }
}


exit;



sub contacts {
    my ($pdbid) = @_;
    # Cached
    my $dbh = connect(dsn(database=>'trans_3_0'));
    # Also cached
    my $sth = $dbh->prepare_cached($sql);
    $sth->execute($pdbid, $pdbid);
    my $rs = $sth->fetchall_arrayref;
    ### $rs
    return $rs;
}


