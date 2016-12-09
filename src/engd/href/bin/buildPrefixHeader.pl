#!/usr/bin/perl

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




# Create a version/prefix header for p8
#
#
# File buildPrefixHeader.pl created by Peterson Dale A. at 09:43:51 on Fri Jun 08 2013.
#
#
# Logic overview:
#
#   Generate unsigned prefix header from file specified
#

# Change flags:
#

# Flag Reason   Date   Pgmr      Description
# ---- -------- ------ --------  ------------------------------------------
# $A0= 881681   061413 dap     : Created program.
#      915553   021114 dap     : Ensure no stray characters at end of hash string 
#

# ===================================================
use Env;
use strict;
# ===================================================
my $ProgName = "buildPrefixHeader.pl";
my $version = "1.1.0";
my $Arg = "";
my @args = @ARGV;
my $Debug = 0;

my $eyeCatcher	= (pack "a8", "VERSION");
my $hashVal	= (pack "x64");
my $headerPad	= (pack "x4024");

my ($cmd,$inputFile,$outputFile,$cmd,$rc,$osName) = "";
# ===================================================
# Check parameters
&parseArgs;

# Open Files
open(OUTPUT, ">$outputFile") or print "$ProgName:	Error: Can't open '$outputFile'\n" and exit -3;

# Create prefix header

# Compute hash of payload and append to header file
my $hashVal = substr(`sha512sum $inputFile \| awk \'\{print $1\}\' \| xxd -ps -r`, 0, 64);

# Write 4k header to file
print OUTPUT "$eyeCatcher$hashVal$headerPad";	

# Close file
close(OUTPUT);

# Append input file to output file
$cmd = "cat $inputFile >> $outputFile ";
&runCmd;	

# Exit
print STDERR "$ProgName:	Info: Prefix header prepended to $inputFile to create $outputFile.\n";	

exit 0;
# ===================================================

sub help {
    if ($#ARGV < 0 || $ARGV[0] eq '-h') {
	print "Usage: \t$ProgName [-h] -outputFile <path/file name> -inputFile <path/file name> [-debug]\n\n";
	print "Example: \t$ProgName -outputFile ~/my_sandbox/ppc/engd/href/centaur_10.sbe_seeprom_hdr.bin  -inputFile /afs/austin/projects/esw/fips810/Builds/built/ppc/engd/href/centaur_10.sbe_seeprom.bin\n\n";
	print "This shell creates a prefix header for the file specified on the '-inputFile' parameter.\n   ";
    }
}

sub parseArgs {
#Check parameters
    while (@args) {
	$Arg = shift(@args);

	if ($Arg =~ m"^-outputFile") {
	    $outputFile = shift(@args);
	    next;
	}
	if ($Arg =~ m"^-inputFile") {
	    $inputFile = shift(@args);
	    next;
	}
	if ($Arg =~ m"^-debug") {
	    $Debug = 1;
	    next;
	}
	if ($Arg =~ m"-h") {
	    &help;
	    exit -1;
	}
    }
# Lid or lid list file is required
    if (!defined $inputFile) {
	&help;
	print STDERR "$ProgName:	Error: Required parameter '-inputFile' not specified exiting.  Exiting\n";	
	exit 255;
    }
# Output file is required.
    if (!defined $outputFile) {
	print STDERR "$ProgName:	Error: Required parameter '-outputFile' not specified.  Exiting\n\n";	
	exit 255;
    }
# Input file must exist if specified
    if (($inputFile ne "") && !(-e "$inputFile")) {
	print STDERR "$ProgName:	Error: Input file: $inputFile does not exist\n\n";	
	exit 255;
    }
}

sub runCmd {
    print STDOUT "$ProgName:	Info: Executing: $cmd\n" if ($Debug);
    $rc = `$cmd &2>&1`;
# For test purposes
#    $rc = `echo $cmd &2>&1`;
    if ($?) {
	print STDERR "$ProgName:	Error executing $cmd\n$rc";
	exit (1);
    }
}
