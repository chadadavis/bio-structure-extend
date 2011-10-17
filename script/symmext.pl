#!/usr/bin/env perl

=head1 NAME

symmext - Take a trimer and use crystal contacts to generate multimers

=head1 SYNOPSIS

 symmext.pl 1abc 1xyz ...

=head1 DESCRIPTION

Assumes that each PDB ID is exactly a 3-mer in the biounit and at least a
4-mer in the PDB deposited structure, also that the deposited structure is
homo-meric.

Requires that the chain IDs are the same between the author-depoisited
structure and the biounit assembly. This is the default of the biounit
(biological unit structures provided by the wwPDB).

=cut

use strict;
use warnings;
use Moose::Autobox;
use IO::Prompt;

use SBG::Run::rasmol qw(rasmol);
use SBG::U::Run qw(start_lock end_lock);

use FindBin '$Bin';
use lib "$Bin/../lib";

use SBG::SymmExt;
#use Devel::Comments;
mkdir 'extensions';

for my $pdbid (@ARGV) {
    my $done_file = "extensions/$pdbid";
    my $lock = start_lock($done_file);
    if (! defined $lock) { next; }

    print "$pdbid : Starting\n";
    my $symmext = SBG::SymmExt->new(pdbid => $pdbid);
    my $contacts = $symmext->crystal_contacts;
    if ($contacts->length == 0) {
        warn "$pdbid : No contacts from Trans DB\n";
        $contacts = $symmext->qcons_contacts;
        if ($contacts->length == 0) {
            warn "$pdbid : No Qcontacts\n";
            end_lock($lock);
            next;
        }
        ### qcons : $contacts;
    }

    my $contact_i = 0;
    my $contact = $contacts->[$contact_i];
    my $save_i = 0;
    while (defined $contact) {
        header($symmext, $contacts, $contact_i);

        my $opt = menu($symmext);

        if (0) {
        }
        elsif ($opt eq 'a') {
            $symmext->apply($contact);
        }
        elsif ($opt eq 'd') {
            last;
        }
        elsif ($opt eq 'q') {
            exit;
        }
        elsif ($opt eq 'n') {
            $contact_i = ++$contact_i % $contacts->length;
            $contact = $contacts->[$contact_i];
        }
        elsif ($opt eq 'r') {
            $symmext->clear_state;
        }
        elsif ($opt eq 's') {
            save($symmext, $save_i++);
        }
        elsif ($opt eq 'u') {
            $symmext->undo;
        }
        elsif ($opt eq 'v') {
            rasmol($symmext->domains->flatten);
        }
    }

    end_lock($lock);

} # for pdbids

sub header {
    my ($symmext, $contacts, $contact_i) = @_;
    my $contact = $contacts->[$contact_i];
    my $n_contacts = $contacts->length;
    print sprintf 
        "\nPDB %s Contact %2d (%s) (of %2d) Sub-complexes %2d\n",
        $symmext->pdbid,
        $contact_i + 1,
        $contact->join('--'),
        $n_contacts,
        $symmext->all->length,
        ;
}

sub menu {
    my ($symmext, $contact_i) = @_;
    my $p = "[v]iew [a]pply [n]ext [u]ndo [r]eset [s]ave [d]one [q]uit : ";
    my $res = prompt $p, qw(-tty -one_char);
    print "\n";
    return $res;
}

sub save {
    my ($symmext, $i ) = @_;
    my $pdbid = $symmext->pdbid;
    my $file = prompt(
        "\nSave to file: ",
        -tty,
        -default => sprintf("extensions/%s-%02d.pdb", $pdbid, $i),
    );
    $file = "$file";
    my $io = $symmext->write($file);
    print 'Saved: ', $io->file, "\n";

}


exit;



