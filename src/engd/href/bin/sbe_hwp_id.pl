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




use strict;
use File::Find ();
use File::Path;
use Cwd;

# Variables
my $ProgName		= "sbe_hwp_id";
my $DEBUG = 0;
my @outputFnVn;
my $baseDir = ".";
my @searchFiles;
my %manifestFileVersion = {};
my $bb = $ENV{'bb'};

my $SHOW_INFO = 0;
# a bit for each:
use constant SHOW_IMAGEID    => 0x01;
use constant SHOW_MISSING    => 0x02;
use constant SHOW_VERSION    => 0x04;
use constant SHOW_SHORT      => 0x08;
use constant SHOW_FULLPATH   => 0x10;
use constant SHOW_HTML       => 0x20;
use constant SHOW_ONLYMISS   => 0x40;

# directories that we'll check for files:
my @dirList = (
#    "src/usr/hwpf/hwp",             # hostboot
#    "src/usr/pore/poreve/model",    # hostboot
#    "src/hwsv/server/hwpf/hwp",     # fsp, should be full tree
    "obj/ppc/engd/href/eclipz",      # sbe, should be full tree
    "src/engd/scandef",              # scandef
    "src/engd/figspy",               # spydef
    "src/engd/scomdef",              # scomdef
    ) ;

# set defaults

$SHOW_INFO = SHOW_VERSION;

while( $ARGV = shift )
{
    if( $ARGV =~ m/-h/ )
    {
        usage();
    }
    elsif( $ARGV =~ m/-D/ )
    {
        if ( $baseDir = shift )
        {
            print("Using directory: $baseDir\n") if ($DEBUG);
        }
        else
        {
            usage();
        }
    }
    elsif( $ARGV =~ m/-d/ )
    {
        $DEBUG = 1;
    }
    elsif( $ARGV =~ m/-f/ )
    {
        $SHOW_INFO |= SHOW_FULLPATH;
    }
    elsif( $ARGV =~ m/-F/ )
    {
        # no directory, list of files
        $baseDir = "";
        @searchFiles = @ARGV;
        last; # done with options
    }
    elsif( $ARGV =~ m/-l/ )
    {
        $SHOW_INFO |= SHOW_HTML;
        $SHOW_INFO &= ~SHOW_VERSION;
        $SHOW_INFO &= ~SHOW_SHORT;
    }
    elsif( $ARGV =~ m/-M/ )
    {
        $SHOW_INFO |= SHOW_ONLYMISS;
    }
    elsif( $ARGV =~ m/-m/ )
    {
        $SHOW_INFO |= SHOW_MISSING;
    }
    elsif( $ARGV =~ m/-s/ )
    {
        $SHOW_INFO |= SHOW_SHORT;
        $SHOW_INFO &= ~SHOW_VERSION;
        $SHOW_INFO &= ~SHOW_HTML;
    }
    elsif( $ARGV =~ m/-v/ )
    {
        $SHOW_INFO |= SHOW_VERSION;
        $SHOW_INFO &= ~SHOW_SHORT;
        $SHOW_INFO &= ~SHOW_HTML;
    }
    else
    {
        usage();
    }
}

if ($SHOW_INFO & SHOW_ONLYMISS)
{
    $SHOW_INFO &= ~SHOW_VERSION;
    $SHOW_INFO &= ~SHOW_SHORT;
    $SHOW_INFO &= ~SHOW_HTML;
}

# get file versions from manifest
&loadManifestVersions;

# generate starting html if needed
if ($SHOW_INFO & SHOW_HTML)
{
    print "<html>\n";
    print "    <head><title>HWP names and version IDs</title></head>\n";
    print <<STYLESHEET;
    <style type="text/css">
        table.hwp_id {
            border-width: 1px;
            border-spacing: 2px;
            border-style: outset;
            border-color: gray;
            border-collapse: separate;
            background-color: white;
        }
        table.hwp_id th {
            border-width: 1px;
            padding: 1px;
            border-style: inset;
            border-color: gray;
            background-color: white;
        }
        table.hwp_id td {
            border-width: 1px;
            padding: 1px;
            border-style: inset;
            border-color: gray;
            background-color: white;
        }
    </style>
STYLESHEET
    print "    <body>\n";
}

# if baseDir - recurse into directories
if ($baseDir)
{
    # make sure we're in the correct place
    chdir "$baseDir";

    # do the work - for each directory, check the files...
    foreach( @dirList )
    {
        @outputFnVn = ();
        checkDirs( $_ );

        if (scalar(@outputFnVn) > 0)
        {
            outputFileInfo($_, @outputFnVn);
        }
    }
}
else # list of files
{
    @outputFnVn = ();

    # do the work - for each file, check it
    foreach( @searchFiles )
    {
        findIdVersion( $_ );
    }

    if (scalar(@outputFnVn) > 0)
    {
        my $pwd = getcwd();
        outputFileInfo($pwd, @outputFnVn);
    }
}
my $extraFilesError = 0;
my $extraFile = "";
#
foreach $extraFile (keys %manifestFileVersion)
{
    if (defined $manifestFileVersion{$extraFile})
      {
	  print "ERROR: Extra files in manifest not found -- $extraFile \n";
	  $extraFilesError++;
      }
}
if ($extraFilesError)
{
    exit 4;
}

# generate closing html if needed
if ($SHOW_INFO & SHOW_HTML)
{
    print "    </body>\n";
    print "</html>\n";
}
exit 0;
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#  End of Main program
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

################################################################################
#
# Print debug messages if $DEBUG is enabled.
#
################################################################################

sub debugMsg
{
    my ($msg) = @_;
    if( $DEBUG )
    {
        print "DEBUG: $msg\n";
    }
}

################################################################################
#
# outputFileInfo - Print output, as options dictate
#
################################################################################

sub outputFileInfo
{
    my $dir = shift;

    if ($SHOW_INFO & SHOW_HTML)
    {
        print("<h2>HWP files in $dir</h2>\n");
    }
    else
    {
        print("[HWP files in $dir]\n");
    }

    if ($SHOW_INFO & SHOW_SHORT)
    {
        print("[Procedure,Revision]\n" );
    }

    if ($SHOW_INFO & SHOW_HTML)
    {
        print "<table class='hwp_id'>\n";
        print "    <tr>\n";
        print "        <th>Filename</th>\n";
        print "        <th>Version</th>\n";
        print "    </tr>\n";
    }

    foreach( sort(@_) )
    {
        print( "$_\n" );
    }

    if ($SHOW_INFO & SHOW_HTML)
    {
        print "</table>\n";
    }
}

################################################################################
#
# findIdVersion - prints out filename and version from the $Id: string.
#
################################################################################

sub findIdVersion
{
    my ($l_file) = @_;
    my $fn = ""; # filename
    my $vn = ""; # version
    debugMsg( "finding Id & Version from file: $l_file" );

    local *FH;
    if (-l $l_file)
    {
	debugMsg( "findIdVersion: Ignoring symbolic link: $l_file" );
	next;
    }
	  
    my $data = "";
    my $localPath = "";

    # Handle large engd src files differently for performance
    if ($l_file =~ m"(spydef$|scandef$|scomdef$)")
    {
	$data = `tail -2 $l_file`;
    }
    else
    {
	open(FH, "$l_file") or die("Cannot open: $l_file: $!");
	read(FH, $data, -s FH) or die("Error reading $l_file: $!");
	close FH;
    }

    # look for special string to skip file
    if ($data =~ /HWP_IGNORE_VERSION_CHECK/ )
    {
        debugMsg( "findIdVersion: found HWP_IGNORE_VERSION_CHECK in: $l_file" );
        next;
    }

    # look for 
    # $Id: - means this IS an hwp - print version and continue
    # else - missing!
    if (($data =~ m"\$Id: (.*),v ([0-9.]*) .* \$"mgo) ||
        ($data =~ m"\$Header: \S+\.cvsroot/(.*),v ([0-9.]*) .* \$"mgo))
    {
	$fn = $1; # filename
	$vn = $2; # version
    }
    if ($data =~ m"\.cvsroot/(.*),v " || $l_file =~ m"(eclipz\S+)" || $l_file =~ m"^(src\S+)") 
    {
	$localPath = "$1";

	if (($l_file =~ m"^src\S+") || (defined $manifestFileVersion{$localPath}) && ($l_file =~ m"\S+/$localPath$"))
	{
	    # For files in the manifest file
	    if ($l_file !~ m"^src\S+")
	    {
	        # Version not in CVS file comment.  Default to manifest file version.
		if ($vn eq "")
		{
		    $vn = $manifestFileVersion{$localPath};
		}
	        # if file is in manifest and versions don't match --> error
		if ($manifestFileVersion{$localPath} ne $vn) 
		{
		    die("ERROR: Version number from manifest does not match version number from tar file for $fn. Manifest version = $manifestFileVersion{$localPath}  Tar version = $vn" );
		}
	    }
	    my $display_name;
	    if ($SHOW_INFO & SHOW_FULLPATH || $fn eq "Makefile"|| $fn eq "mymakefile.ecmd.demo")
	    {
		$display_name = $localPath;
	    }
	    else
	    {
		$display_name = $fn;
	    }
	    debugMsg( "File: $display_name  Version: $vn" );
	    if ($SHOW_INFO & SHOW_VERSION)
	    {
		push( @outputFnVn, "File: $display_name  Version: $vn" );
	    }
	    elsif ($SHOW_INFO & SHOW_SHORT)
	    {
		push( @outputFnVn, "$display_name,$vn" );
	    }
	    elsif ($SHOW_INFO & SHOW_HTML)
	    {
		push( @outputFnVn, "<tr><td>$display_name</td><td>$vn</td></tr>" );
	    }

	    # Clear entry 
	    undef $manifestFileVersion{"$localPath"};
	}
	else
	{
	    debugMsg( "findIdVersion: MISSING \$Id tag: $l_file" );
	    if ($SHOW_INFO & SHOW_MISSING)
	    {
		if ($SHOW_INFO & SHOW_VERSION)
		{
		    print( "File: $localPath  Version: \$Id is MISSING\n" );
		}
		elsif ($SHOW_INFO & SHOW_SHORT)
		{
		    print( "$localPath,MISSING\n" );
		}
		elsif ($SHOW_INFO & SHOW_HTML)
		{
		    print( "<tr><td>$localPath</td><td>\$Id is MISSING</td></tr>\n" );
		}
	    }
	    elsif ($SHOW_INFO & SHOW_ONLYMISS)
	    {
		print( "File: $localPath  Version: \$Id is MISSING\n" );
	    }
	}
    }
}

################################################################################
#
# checkDirs - find *.[hHcC] and *.initfile files that are hwp files
# and prints out their filename and version from the $Id: string.
# This recursively searches the input directory passed in for all files.
#
################################################################################

sub checkDirs
{
    my ($l_input_dir) = @_;

    debugMsg( "Getting Files for dir: $l_input_dir" );

    # Open the directory and read all entry names.
            
    local *DH;
    opendir(DH, $l_input_dir) ;#or die("Cannot open $l_input_dir: $!");
    # skip the dots
    my @dir_entry;
    @dir_entry = grep { !/^\./ } readdir(DH);
    closedir(DH);
    while (@dir_entry)
    {
        my $l_entry = shift(@dir_entry);
        my $full_path = "$l_input_dir/$l_entry";

        debugMsg( "checkDirs: Full Path: $full_path" );

        # else if this is a directory
        if (-d $full_path)
        {
	    if (!(-l $full_path))
	    {
            # recursive here
            checkDirs($full_path);
	    }
        }
        # if this is valid file:
#        elsif (($l_entry =~ /\.[H|h|C|c]$/) ||
#            ($l_entry =~ /\.initfile$/))
        elsif ($full_path !~ /CVS/) 
        {
            findIdVersion($full_path);
	}
        # else we ignore the file.
    }
}

################################################################################
#
# Print the Usage message
#
################################################################################

sub usage
{
    print "Usage: $0 <option> [-F <files>]\n";
    print "\n";
    print "Default - show name and version for hwp files with \$Id string.\n";
    print "-D dir    Use dir as top of build.\n";
    print "-d        Enable Debug messages.\n";
    print "-f        Show full pathname of all files.\n";
    print "-F files  Search listed full-path files. Must be last parameter.\n";
    print "-h        Display usage message.\n";
    print "-m        Include files that are missing Id strings.\n";
    print "\n";
    print " output is in one of 4 formats:\n";
    print "-l        Output in html table.\n";
    print "-s        Show short \"filename,version\" format.\n";
    print "-v        Show longer \"File: f Version: v\" format. (default)\n";
    print "-M        Only show files that are missing Id strings.\n";
    print "\n";
    exit 1;
}

sub loadManifestVersions
{
    my $Line = "";
    my $manifestFile = "$baseDir/src/engd/href/href.manifest";
    if (!-e $manifestFile) {
	$manifestFile = "$bb/src/engd/href/href.manifest";
    }
    debugMsg( "loadManifestVersions: Using manifest file: $manifestFile" );
    open(INPUTFILE, "$manifestFile") or print "$ProgName:	Error: Can't open '$manifestFile'\n" and exit -3;
    while ($Line = <INPUTFILE>) {
	chomp $Line;
	if (($Line =~ m"^(\S+)\|(\S+)") && ($Line !~ m"^#")) {
	    $manifestFileVersion{$1} = $2;  
	}
    }
    close INPUTFILE;
}
