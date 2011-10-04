#!/usr/bin/env perl

=head1 NAME

SymmExt - 

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

package SBG::SymmExt;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(assembly2doms);

=head2 

TODO Belongs in SBG::Domain or BioX::Structure::Complex

=cut

sub assembly2doms {
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
            my %defaults = ( 
                pdbid      => $assembly->pdbid,
                descriptor => 'CHAIN ' . $chain->id,
            );
            if (defined $assembly->assembly) {
                $defaults{assembly} = $assembly->assembly;
                $defaults{model}    = $model->id;
            }

            my $dom = SBG::Domain->new(%defaults);

            ### $dom
            ### file : $dom->file
            push @doms, $dom;
        }
    }
    return @doms;
}
