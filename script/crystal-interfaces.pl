#!/usr/bin/env perl

=head1 NAME

crystal-interfaces - 

=head1 SYNOPSIS



=head1 DESCRIPTION

Crystal interfaces extracted from symmetry operators

=cut

use Moose::Autobox;
use PDL;

# Local libraries
use FindBin qw/$Bin/;
use lib "$Bin/../lib/";

use Log::Any qw/$log/;

use SBG::Domain;
use SBG::U::Test qw/pdl_equiv/;
use SBG::DomainIO::pdb;
use SBG::Run::rasmol;
use SBG::U::Log;

use Bio::Tools::Run::QCons;
use SBG::Run::naccess qw/sas_atoms buried/;

use PBS::ARGV qw/qsub/;

my $DEBUG;
$DEBUG = 1;
$File::Temp::KEEP_ALL = $DEBUG;

my @jobids = qsub(throttle=>1000, blocksize=>10, options=>\%ops);
exit unless @ARGV;

SBG::U::Log::init(undef, loglevel=>'DEBUG') if $DEBUG;


foreach my $pdbid (@ARGV) {

my $dom = SBG::Domain->new(pdbid=>$pdbid);
my $symops = $dom->symops;

my $no_rotation = pdl [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1];
my $no_translation = pdl(0,0,0)->transpose;

my $noutputs;

foreach my $symop (@$symops) {

    # Skip if there is a rotation
    my $rot = $symop->rotation;
    unless (pdl_equiv($rot, $no_rotation)) {
        $log->debug("Skipping rotation: $rot");
        next;
    }

    # Skip if there is no translation
    my $transl = $symop->translation;
    if (pdl_equiv($transl, $no_translation)) {
    	$log->debug("Skipping translation: $transl");
    	next;
    }
    
    # How many different dimers have we produced so far
    $noutputs++;
    # Create the crystal-induced neighbor domain
    my $crystal_neighbor = $dom->clone;
    $symop->apply($crystal_neighbor);
    # Write the dimer to a PDB file
    my $base = sprintf("%s-%02d", $pdbid, $noutputs);
    my $outfile = $base . '.pdb';
    my $pdbio = SBG::DomainIO::pdb->new(file=>">$outfile");
    $pdbio->write($dom, $crystal_neighbor);
    
    # Check contact, with Qcontacts
    $log->debug("outfile:$outfile");
    my $qcons = Bio::Tools::Run::QCons->new(file=>$outfile, chains => ['A', 'B']);
    # Summarize by residue (rather than by atom)
    my $res_contacts = $qcons->residue_contacts;
    unless ($res_contacts->length) {
        $log->info("$outfile not in contact");
        # Don't save this PDB file if the dimer is not actually an interface
        unlink $outfile;
    	next;
    } else {
        $log->debug("$outfile via: $symop");
    }
#    my $atom_contacts = $qcons->atom_contacts;
    
    # Buried surface
    my $buried = buried($dom, $crystal_neighbor);
    
    print sprintf "%s\t%d\t%.2f\n", $outfile, $res_contacts->length, $buried;
    open my $fh, ">${base}.csv";
    foreach my $contact ($res_contacts->flatten) {
    	my $a = $contact->{'res1'}{'name'} . $contact->{'res1'}{'number'};
    	my $b = $contact->{'res2'}{'name'} . $contact->{'res2'}{'number'};
    	print $fh join("\t", $outfile, $a, $b), "\n";
    }
    
#    rasmol($dom, $crystal_neighbor);
    
    
} # foreach my $symop

} # foreach my $pdbid
