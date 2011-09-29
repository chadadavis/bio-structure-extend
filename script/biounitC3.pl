#!/usr/bin/env perl

=head1 NAME

biounitC3.pl - Determine if a biounit has C3 symmetry

=head1 SYNOPSIS

 biounitC3.pl 1g3n 5gag 2sge 1k3k ...

=head1 DESCRIPTION

prints whether C3 symmetry is found, or not, in TSV format. First colum is the
PDB ID, second is either 'C3' or 'C0'.

Also puts 'C3' or 'C0' into the file ./C3/<pdbid>.txt

Also runs rasmol to display the biounit for visual verification. Uses the
Russell group 'ras' tool.

=cut

use strict;
use warnings;
use Devel::Comments;
use File::Basename;
use IO::Uncompress::Gunzip;
use Bio::Structure::IO::pdb;

#use lib "$ENV{HOME}/src/sbglib/lib";

use SBG::Domain;
use SBG::Transform::Affine;
use SBG::Superposition::Cache qw/superposition/;
use PBS::ARGV;

use SBG::Debug;

# TODO make this a wiki demo
for my $pdbid (@ARGV) {
    $pdbid = lc $pdbid;
    ### $pdbid
    next if -r "C3/$pdbid.txt";

    # Use first biounit assembly by default
    my $assembly = SBG::Domain->new(pdbid => $pdbid, assembly => 1);
    my @doms = _assembly2doms($assembly);
    if (@doms != 3) { next; }

    if (@doms != 3) {
        print "$pdbid ", scalar(@doms), "-mer\n";
        next;
    }
    
    my $is_ring = _is_ring(@doms);
    my $cn = $is_ring ? scalar(@doms) : 0;
    print "$pdbid\tC$cn\n";
#    if ($is_ring) {
        `echo C$cn >| C3/$pdbid.txt`;
#    }
    my $dir = substr($pdbid, 1, 2);
    system("ras \$DS/pdb-biounit/${dir}/$pdbid.pdb1.gz >/dev/null 2>/dev/null");
}


exit;

=head2 

Are the superpositions from 1 to 2 the same as 2 to 3, etc. 
Specific to 3mers, otherwise need to determine topology ordering around ring

=cut

sub _is_ring {
    my @doms = @_;
    my @transformations;
    for (0..$#doms) {
        my $next = ($_ + 1) % @doms;
        my $superposition = superposition($doms[$_], $doms[$next]);
        ### superposition : $_
        ### defined       : defined($superposition)
        if (! defined $superposition) { return; }
        ### scores : $superposition->scores
        my $m = $superposition->transformation->matrix;

        $transformations[$_] = $superposition->transformation;
        if ($_ > 0) {
            my $prev = $transformations[$_ - 1];
            my $curr = $transformations[$_];
            # Equivalent to within N% (but no stricter than 0.1

            # Lenient check here
            my $equal = $prev->equals($curr, '50%', 5);
            ### $equal

            # Don't really need to even test the matrixes
            # Whether STAMP creates a superposition is a metric enough
            if (! $equal) { return; }

        }
    }

    # Stricter check at the end, product of all should be identity

    my $prod = SBG::Transform::Affine->new;
    for my $transformation (@transformations) {
        # Apply the current transformation to the running product
        $transformation->apply($prod);
    }
    my $mat = $prod->matrix;
    ### product : "$mat"
    my $ident = SBG::Transform::Affine->new;
    # initialize lazy build of matrix
    $ident->matrix;
    my $equal = $prod->equals($ident, '15%', .5);
    ### $equal

    return $equal;
}

sub _assembly2doms {
    my ($assembly) = @_;
    my $gunzipped = IO::Uncompress::Gunzip->new($assembly->file);
    # PDB parser to determine the models and chain in one assembly
    my $io = Bio::Structure::IO->new(
        -format => 'pdb',
        -fh     => $gunzipped,
    );

    my $entry  = $io->next_structure;
    my @models = $entry->get_models;
    my @doms;
    for my $model (@models) {
        my @chains = $entry->get_chains($model);
        for my $chain (@chains) {
            my $dom = SBG::Domain->new(
                pdbid      => $assembly->pdbid,
                assembly   => 1,
                model      => $model->id,
                descriptor => 'CHAIN ' . $chain->id,
            );
            ### $dom
            ### file : $dom->file
            push @doms, $dom;
        }
    }
    return @doms;
}
