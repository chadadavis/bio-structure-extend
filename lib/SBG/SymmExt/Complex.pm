#!/usr/bin/env perl

=head1 NAME

SBG::SymmExt::Complex - Simple contains for L<SBG::Domain> objects

=head1 SYNOPSIS

 use SBG::SymmExt::Complex;
 my $biounit = SBG::SymmExt::Complex->new(
     pdbid => '1abc',
     assembly => 1, 
 );

 my $author_deposited = SBG::SymmExt::Complex->new(
     pdbid => '1abc',
     # No assembly provided here
 );

=head1 DESCRIPTION

Placeholder class until BioX::Structure::Complex is complete

=head1 SEE ALSO

=over 4

=item * L<SBG::SymmExt>

=back

=cut

# Must be loaded before MooseX::Declare
#use Devel::Comments;

use MooseX::Declare;
class SBG::SymmExt::Complex {

use strict;
use warnings;
use Storable qw/dclone/;
use Moose::Autobox;
use Bio::Structure::IO;

use SBG::Domain;


has 'pdbid'    => (is => 'ro', isa => 'Str');
has 'assembly' => (is => 'ro', isa => 'Int');
has 'domain'   => (
    is => 'ro', isa => 'HashRef[SBG::Domain]', lazy_build => 1,
);

method chains {
    return $self->domain->keys;
}

method _build_domain {
    # Create a SBG::Domain to lookup the file
    # TODO might want to save this in an attr (later)
    # Copy default attributes from self (hash slice)
    my $opts = $self->Moose::Autobox::Hash::hslice([qw(pdbid assembly)]);
    my $domain = SBG::Domain->new(%$opts);
    my $gunzipped = IO::Uncompress::Gunzip->new($domain->file);
    # PDB parser to determine the models and chain in one assembly
    my $io = Bio::Structure::IO->new(
        -format => 'pdb',
        -fh     => $gunzipped,
    );

    my $entry  = $io->next_structure;
    my @models = $entry->get_models;
    my %domain;
    for my $model (@models) {
        ### $model
        my @chains = $entry->get_chains($model);
        for my $chain (@chains) {
            # a couple default attributes to copy
            my $copy = { %$opts };
            $copy->{descriptor} = 'CHAIN ' . $chain->id;
            if ($model->id ne 'default') { $copy->{model} = $model->id; }
            my $dom = SBG::Domain->new(%$copy);
            $domain{$chain->id} = $dom;
        }
    }
    return \%domain;
}

method domains {
    return $self->domain->values;
}

# Hash slice
method _hslice (@fields) {
    return { map { $_ => $self->{$_} } @fields };
}

method clone {
    return dclone $self;
}

} # class
