#!/usr/bin/env perl

=head1 SYNOPSIS

Run all tests in all loaded subclasses of Test::Class:

 prove -l

Run a single test:

 prove -l t/lib/Test/Bio/Structure/SymmExt.pm

=head1 SEE ALSO

L<Test::Class>

=cut

use FindBin qw/$Bin/;
use Path::Class;

# Alternatively, automatically load all classes in a directory 
# Load all *.pm test classes under ../t/lib/*
use Test::Class::Load dir $Bin, 'lib';

Test::Class->runtests();

