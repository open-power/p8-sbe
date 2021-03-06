#!/usr/bin/perl -w

# IBM_PROLOG_BEGIN_TAG                                                   
# This is an automatically generated prolog.                             
#                                                                        
# OpenPOWER Project                                             
#                                                                        
# Contributors Listed Below - COPYRIGHT 2012,2016                        
# [+] International Business Machines Corp.                              
#                                                                        
#                                                                        
# Licensed under the Apache License, Version 2.0 (the "License");        
# you may not use this file except in compliance with the License.       
# You may obtain a copy of the License at                                
#                                                                        
#     http://www.apache.org/licenses/LICENSE-2.0                         
#                                                                        
# Unless required by applicable law or agreed to in writing, software    
# distributed under the License is distributed on an "AS IS" BASIS,      
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        
# implied. See the License for the specific language governing           
# permissions and limitations under the License.                         
#                                                                        
# IBM_PROLOG_END_TAG                                                     





#
# includes
#

use strict;
use File::Basename;
use File::Spec;
use Getopt::Std;


#
# globals
#

# base image to update
my $BASE_IMAGE;
# hash containing files to include in TOC BOM
my %BOM;
# string to store in TOC
my $TOC_STRING = "\n";

# path to EKB
my $EKB;
if($ENV{EKB}) {
    $EKB=$ENV{EKB};
} else {
    $EKB = $ENV{LABPS};
    $EKB =~ s|lab/p8|KnowledgeBase/eclipz|;
}

# list of files to statically include in TOC BOM, in addition to those automatically determined
# from Makefile/dependency file processing
my %BOM_ADD    = ( "Makefile" => 1,                                    # include Makefile version used in build
                   "generateSBEImageBOM.pl" => 1,                      # this tool
                   "${EKB}/porebinutils/pore-elf64-as" => 1,           # porebinutils
                   "${EKB}/porebinutils/pore-elf64-ld" => 1,           #
                   "${EKB}/porebinutils/pore-elf64-objcopy" => 1,      #
                   "${EKB}/porebinutils/pore-elf64-objdump" => 1,      #
                   "${EKB}/poreve/working/tools/hook_extractor" => 1,  # hook extract/index utilities
                   "${EKB}/poreve/working/tools/hook_indexer" => 1);   #

# list of files to ignore when processing Makefile/dependency files
my %BOM_IGNORE = ( "fapiHwpReturnCodes.H" => 1);                       # this is autogenerated from XML


#
# parse options
#

our $opt_d;
our $opt_c;
getopts("dc");
my $DEBUG = 0;
my $CENTAUR = 0;
if (defined($opt_d)) {
  $DEBUG = 1;
}
if (defined($opt_c)) {
  $CENTAUR = 1;
}

$BASE_IMAGE = $ARGV[0];


#
# start with set of files to include statically
#

@BOM{keys %BOM_ADD} = values %BOM_ADD;


#
# process Makefile to obtain XML dependencies
#

if ($DEBUG) {
  printf("Processing Makefile to obtain XML files...\n");
}

my $in_xml = 0;
open(MAKEFILE, "Makefile") or die "Can't open Makefile for reading!";
while (my $line = <MAKEFILE>) {
  chomp($line);
  if ($in_xml) {
    if ($line =~ /(\S+).xml/) {
      my $dep = basename($1) . ".xml";
      if ($DEBUG) {
        printf("  Found ${dep}\n");
      }
      $dep = "../../xml/error_info/" . ${dep};
      $BOM{$dep} = "UNKNOWN";
    }
    else {
      $in_xml = 0;
      last;
    }
  }
  if ((!$CENTAUR && ($line =~ /^HALT-CODES\s+=\s+\\/)) ||
      ($CENTAUR && ($line =~ /^SBE-PNOR-XML-SOURCES\s+=\s+\\/))) {
    $in_xml = 1;
  }
}
close(MAKEFILE);


#
# process build directory for all dependency files generated by image make process
#

if ($DEBUG) {
  printf("Processing build dependency files...\n");
}

opendir(BINDIR, 'bin') or die "Can't access directory \"bin\" for reading!";
while (my $file = readdir(BINDIR)) {
  # process only .d files
  next if ($file !~ /.d$/);
  if ($DEBUG) {
    printf("Searching ${file}...\n");
  }
  open(DEPFILE, "bin/${file}") or die "Can't open file \"bin/${file}\" for reading!";
  my $first_line = 1;
  while (my $line = <DEPFILE>) {
    chomp($line);
    if ($first_line && $line =~ /(.*):(.*)/) {
      $line = $2;
    }
    # strip EOL indicators
    $line =~ s/\\//g;
    # strip whitespace
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my @deps = split(/\s+/, $line);
    foreach my $dep (@deps) {
      if (!defined($BOM_IGNORE{basename($dep)})) {
        if ($DEBUG) { printf("  Adding dependency: %s\n", $dep); }
        $BOM{$dep} = "UNKNOWN";
      }
    }
    $first_line = 0;
  }
  close(DEPFILE);
}
closedir(BINDIR);


#
# determine CVS level of all dependencies
#

if ($DEBUG) {
  printf("Determining CVS levels...\n");
}

foreach my $dep (sort(keys %BOM)) {
  my $dep_dir = dirname($dep);
  my $dep_file = basename($dep);
  if ($DEBUG) {
    printf("  Searching for $dep_dir/$dep_file\n");
  }

  # Centaur make process relies directly on a copy of
  # several files from the parallel P8 dir tree, fetch
  # CVS info from there
  if ($CENTAUR &&
      (($dep_file eq "generateSBEImageBOM.pl") ||
       ($dep_file eq "proc_sbe_common.S") ||
       ($dep_file eq "sbe_common_halt_codes.xml"))) {
    $dep_dir = File::Spec->rel2abs($dep_dir);
    $dep_dir =~ s|/eclipz/chips/centaur|/eclipz/chips/p8/|;
    if ($DEBUG) {
      printf("  ** Altering path...\n");
      printf("  $dep_dir/$dep_file\n");
    }
  }
  my $cvs_version = `grep ${dep_file} ${dep_dir}/CVS/Entries`;
  chomp($cvs_version);
  if ($cvs_version =~ /\/${dep_file}\/(\S+)\//) {
    $cvs_version = $1;
    if ($DEBUG) {
      printf("    Found: ${cvs_version}\n");
    }
  }
  else {
    die "Error determining CVS revision level for ${dep_file}!";
  }
  $TOC_STRING .= "${dep_file} : ${cvs_version}\n";
}


#
# write TOC string into base image
#

if ($DEBUG){
  my $bytes;

  {
    use bytes;
    $bytes = length($TOC_STRING);
  }

  printf("Updating image TOC (size = %d B, %d chars)!\n", $bytes, length($TOC_STRING));
}
system("sbe_xip_tool ${BASE_IMAGE} set source_revision \"${TOC_STRING}\"");
die "ERROR updating TOC BOM!" if ($?);

exit 0;
