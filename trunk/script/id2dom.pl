#!/usr/bin/env perl

=head1 NAME

id2dom - create STAMP DOM files for the PDB IDs in column 1 of a CSV file

=head1 SYNOPSIS

 id2dom some_data.csv


=head1 DESCRIPTION

DOM files are created in the current directory, like: 1tim.dom

=cut

# Given a list of IDs (CSV) input, produce STAMP DOM format files

use strict;
use warnings;
use autodie;
use Text::CSV;
my $csv_file = shift or die "Usage: $0 <csv_file.csv>\n";
my $csv = Text::CSV->new({ sep_char => "\t" });
open my $io, '<', $csv_file;
while (my $row = $csv->getline($io)) {
    my $id = $row->[0];
    print "$id\n";
    id2dom($id);
}


sub id2dom {
    my ($id) = @_;
    system("pdbc -d $id > $id.dom");
}
