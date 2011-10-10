#!/usr/bin/env perl

=head1 NAME

no-db-contacts - Find out which structures not yet in Trans DB

=head1 SYNOPSIS

 no-db-contacts 1abc 1xyz ...

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Moose::Autobox;

use FindBin '$Bin';
use lib "$Bin/../lib";

use SBG::SymmExt;

for my $pdbid (@ARGV) {
    my $symmext = SBG::SymmExt->new(pdbid => $pdbid);
    my $contacts = $symmext->crystal_contacts;
    if ($contacts->length == 0) {
        warn "$pdbid\n";
    }

} # for pdbids


exit;



