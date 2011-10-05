#!/usr/bin/env perl

=head1 SYNOPSIS

Run all tests in all loaded subclasses of Test::Class:

 prove -l

Run a single test:

 prove -l t/lib/Test/SBG/SymmExt.pm

=head1 SEE ALSO

L<Test::Class>

=cut

use FindBin qw/$Bin/;

# Alternatively, automatically load all classes in a directory 
# Load all *.pm test classes under ../t/lib/*
use Test::Class::Load "$Bin/lib";

Test::Class->runtests();

