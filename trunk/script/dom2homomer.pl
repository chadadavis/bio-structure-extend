#!/usr/bin/env perl

=head1 NAME

dom2homomer - determines if the STAMP DOM file domains are structurally equiv

=head1 SYNOPSIS

 dom2homomer *.dom


=head1 DESCRIPTION

Print the file names of the files that contains only homomeric
components. Note that each entry is a domain. It doesn't pick apart
multi-meric complexes. You should use pdbc for that. I.e. the DOM file should be 
 /path/to/1tim.pdb.gz 1timA { CHAIN A }
 /path/to/1tim.pdb.gz 1timB { CHAIN B }

Because that contains two entries that can be compared, whereas this only contains a single entry and is therefore homomeric by definition, regardless of whether CHAIN A and CHAIN B are similar or not:

 /path/to/1tim.pdb.gz 1tim { ALL }

=cut

use strict;
use warnings;

use Algorithm::DistanceMatrix;
use Algorithm::Cluster::Thresh 0.04;
use Algorithm::Cluster qw/treecluster/;
use List::Util qw/max/;
use List::MoreUtils qw/uniq/;

use SBG::DomainIO::stamp;
use SBG::Superposition::Cache qw/superposition/;
use PBS::ARGV;

#use Devel::Comments;

for my $dom_file (@ARGV) {
    my $io = SBG::DomainIO::stamp->new(file => $dom_file);
    my $basename = _basename($dom_file);
    print $basename;
    my @domains = $io->read;

    my $dist_mat = Algorithm::DistanceMatrix->new(
        metric => \&_distance,
        objects => \@domains,
    );
    my $raw_mat = $dist_mat->distancematrix;

    my $tree = treecluster(data=>$raw_mat, method=>'a'); # 'a'verage linkage
    my $cluster_ids = $tree->cutthresh(8.0);
    print "\t", max(@$cluster_ids);
    print "\n";
}

sub _distance {
    my ($a, $b) = @_;
    my $superposition = superposition($a, $b);
    defined $superposition or return 'Inf';
    my $Sc_score = $superposition->scores->{Sc};
    return 10 - $Sc_score;
}

sub _basename {
    my $basename = shift;
    $basename =~ s|^.*/||;
    $basename =~ s|\..*$||;
    return $basename;
}
