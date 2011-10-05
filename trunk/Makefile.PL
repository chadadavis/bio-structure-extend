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

requires "SBG::Debug" => "0";
requires "SBG::Domain" => "0";
requires "SBG::DomainIO::pdb" => "0";
requires "SBG::DomainIO::stamp" => "0";
requires "SBG::Run::rasmol" => "0";
requires "SBG::Transform::Affine" => "0";
requires "SBG::U::List" => "0";
requires "SBG::Superposition::Cache" => "0";

requires "Class::MOP" => "2.0205";
requires "Class::MOP::Class::Immutable::Trait" => "2.0205";
requires "Cwd" => "3.33";
requires "Data::Dump" => "1.19";
requires "Data::OptList" => "0.107";
requires "Data::Show" => "0.001002";
requires "Devel::GlobalDestruction" => "0.04";
requires "Eval::Closure" => "0.06";
requires "List::MoreUtils" => "0.33";
requires "List::Util" => "1.23";
requires "MRO::Compat" => "0.11";
requires "Moose::Autobox" => "0.11";
requires "Moose::Error::Util" => "0";
requires "Moose::Util::TypeConstraints::Builtins" => "2.0205";
requires "Package::DeprecationManager" => "0.11";
requires "Package::Stash" => "0.32";
requires "Package::Stash::XS" => "0.25";
requires "Params::Util" => "1.04";
requires "Perl6::Junction" => "1.40000";
requires "Scope::Guard" => "0.20";
requires "Storable" => "2.30";
requires "Sub::Exporter" => "0.982";
requires "Sub::Install" => "0.925";
requires "Sub::Name" => "0.05";
requires "Try::Tiny" => "0.11";
requires "autobox" => "2.75";
requires "autobox::universal" => "0";

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


