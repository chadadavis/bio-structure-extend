#!/usr/bin/env perl

=head2 UPDATE

Update this list with

 make distclean
 files=`find . -name '*.pl' -o -name '*.t' -o -name '*.pm' | xargs`
 perl -d:Modlist=stop,nocore,cpan,zerodefault,stdout $files | \
     perl -lane 'next if /^SBG/;print "requires \"$F[0]\" => \"$F[1]\";"' >| \
     requires.txt

And then replace the 'requires' lines below with that 'requires.txt'

=cut 

use inc::Module::Install;
use Module::AutoInstall;

name 'SBG-SymmExt';
# Collect metadata from the following module
all_from 'lib/SBG/SymmExt.pm';

requires "Algorithm::Cluster" => "0";
requires "Algorithm::Cluster::Thresh" => "0";
requires "Algorithm::DistanceMatrix" => "0";
requires "Bio::Structure::IO" => "0";
requires "Bio::Structure::IO::pdb" => "0";
requires "Bio::Tools::Run::QCons" => "0";
requires "Config" => "0";
requires "Cwd" => "0";
requires "DBI" => "0";
requires "Data::Dump" => "0";
requires "Data::Show" => "0";
requires "Devel::Comments" => "0";
requires "ExtUtils::MakeMaker" => "0";
requires "Fcntl" => "0";
requires "File::Basename" => "0";
requires "File::Find" => "0";
requires "File::Path" => "0";
requires "File::Spec" => "0";
requires "FindBin" => "0";
requires "Graph::Undirected" => "0";
requires "IO::Prompt" => "0";
requires "IO::Uncompress::Gunzip" => "0";
requires "List::MoreUtils" => "0";
requires "List::Util" => "0";
requires "Log::Any" => "0";
requires "Module::AutoInstall" => "0";
requires "Module::Install::Base" => "0";
requires "Moose::Autobox" => "0";
requires "MooseX::Declare" => "0";
requires "PBS::ARGV" => "0";
requires "PDL" => "0";
requires "Set::Scalar" => "0";
requires "Storable" => "0";
requires "Test::Class::Load" => "0";
requires "Test::More" => "0";
requires "Text::CSV" => "0";
requires "inc::Module::Install" => "0";

# Only required for testing
test_requires 'Test::Class' => '0';
test_requires 'Test::More' => '0';

# install_script glob('script/*.pl');

# Automagically install above deps from CPAN
auto_install();


# If we used Test::Class everywhere, this would be sufficient
WriteAll;

# And if you don't need a "Pure Perl" solution, this is sufficient:
# WriteMakefile(test => {TESTS => `find t -name '*.t' | xargs` });

# But instead do recursive search for ./t/*.t files
#use File::Find;
#my @tests;
#find(sub { push @tests, $File::Find::name if /\.t$/ }, 't');

#WriteMakefile(test => { TESTS => "@tests" });


