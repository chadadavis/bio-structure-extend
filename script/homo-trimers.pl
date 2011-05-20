#!/usr/bin/env perl

use Moose;
use Moose::Autobox;
use File::Spec::Functions;

use SBG::Domain;

use Bio::Structure::IO::pdb;
use IO::Uncompress::Gunzip;

foreach my $pdbid (@ARGV) {

    # Check each biological assembly
    my $mid2 = substr($pdbid, 1, 2);
    my $base = catfile($ENV{'DS'}, 'pdb-biounit', $mid2, $pdbid . '.pdb');
    foreach my $file (<$base*>) {
        print $file, "\n";
        my $fh = IO::Uncompress::Gunzip->new($file);
        my $io = Bio::Structure::IO::pdb->new(-fh=>$fh);
        while (my $entry = $io->next_structure) {
            print "\tEntry ", $entry->id, "\n";
            my @chains;
            foreach my $model ($entry->get_models) {
#                print "\t\tModel ", $model->id, "\n";
                foreach my $chain ($entry->get_chains($model)) {
#                    print "\t\t\tChain ", $chain->id, "\n";
                    push @chains, {model=>$model,chain=>$chain};
                }
            }
            foreach my $chain (@chains) {
                my $model = $chain->{model};
                my $chain = $chain->{chain};
                print "\tModel ", $model->id, " Chain ", $chain->id, "\n";
            }
        }
    }

   
}


