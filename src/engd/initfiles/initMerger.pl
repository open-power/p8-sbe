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




##################################################
# This program merges initfiles into a single one so it can be compiled.
##################################################

###########################################################################
#Change Log
###########################################################################
#  Flag    Reason   Userid    Date        Description
#  -----   ------   ------    --------    ---------------------------------
#          583506   spinler   12/08/06    Created
#          648289   spinler   02/07/08    Add END_INITFILE keyword
#          909287   dpeterso  01/02/14    Set exit code to '1' if no input files.
#                                         Since script is typically used in makefile
#                                         usage is not valid output.
###########################################################################



use strict;

my $USAGE = "Usage:   initMerger.pl -o <output.initfile> -i <file1.initfile> -i <file2.initfile> ...[-h]\n";
my $progName = "initMerger.pl";
my $MERGE_VERSION = "2"; #syntax version of a merged initfile
my $outputFile;
my %initfiles;
my $rc = 0;
my $filename;
my @path;



if ($#ARGV < 5 || $ARGV[0] eq '-h') {
   print "$USAGE";
   exit 1;
}


#Get the args
my $i = 0;
for ($i=0;$i<=$#ARGV;$i++) {

   if ($ARGV[$i] eq "-o") {
      $i++;
      $outputFile = $ARGV[$i];
   }
   elsif ($ARGV[$i] eq "-i") {
      $i++;     
      @path = split("/", $ARGV[$i]);           
      $filename = $path[$#path];
      $initfiles{$filename}{PATH} = $ARGV[$i];
   } 
   else {
      print "ERROR: Invalid input $ARGV[$i]\n";
      die "$USAGE";      
   }
}

if (not defined $outputFile) {  
   print "ERROR: Output file not defined\n";
   die "$USAGE"; 
}

if (keys(%initfiles) == 0) {
   print "ERROR: Input files not defined\n";
   die "$USAGE";
}

#Look for some keywords
&scanFiles();

#Create the merged files
&mergeFiles();


exit $rc;

#####End of main program



#################################################
sub scanFiles() {
   my $file;
   my @line;
   my @sub;
   my $version;
   my $temp;
   my $hierarchies;

   for $file (sort keys %initfiles) {
      print "Reading $file\n";
      open FILE, "$initfiles{$file}{PATH}" or die "Could not open $initfiles{$file}{PATH}\n";

      while (<FILE>) {

         #look for the CVS version
         if (/\$Id: /) {
            @line = split( ",v ", $_ );
            @sub  = split( ' ',   $line[1] );
            $version = $sub[0];

            $initfiles{$file}{VERSION} = $version;
            print "  Found version $version\n";
         }

         #look for the Syntax Version
         if (/^\s*SyntaxVersion/i) {         
            ($temp, $version) = split('=', $_);
            $version =~ s/\s+//g;
            chomp($version);
            if ($version !~ /[0-9.]+/) {
               die "Bad syntax version $version in file $initfiles{$file}{PATH}\n";
            }
            $initfiles{$file}{SYNTAXVERSION} = $version;
            print "  Found syntax version $version\n";         
         }

         #look for the instance hierarchy
         if (/^\s*InstanceHierarchy/i) {
            ($temp, $hierarchies) = split('=', $_);
            chomp($hierarchies);
            $hierarchies =~ s/\s//g;

            $initfiles{$file}{HIERARCHIES} = $hierarchies;

            print "  Found instance hierarchies $hierarchies\n"           
         }

         #look for the MAXEC if there
         if (/^\s*MAXEC/i) {
            my ($temp, $maxec) = split("=", $_);
            $maxec =~ s/\s//g; #take out any spaces
            $initfiles{$file}{MAXEC} = $maxec;         
            print "  Found MaxEC $maxec\n";
         }

         #See if we're done
         last if ((exists $initfiles{$file}{VERSION}) &&
                  (exists $initfiles{$file}{SYNTAXVERSION}) &&
                  (exists $initfiles{$file}{HIERARCHIES}) && 
                  (exists $initfiles{$file}{MAXEC}));
         
      }


      close FILE;  
   }

}

#################################################
sub mergeFiles {
   my $if;   

   print "\nMerging files into $outputFile\n";

   open OUTFILE, ">$outputFile" or die "Could not open output file $outputFile\n";

   ###file header
   &printHeader();

   print OUTFILE "\n\n#######################################################\n";
   print OUTFILE "#Initfile Header Section:\n";

   ###component file versions
   &printVersions();

   ###Syntax Version
   &printSyntaxVersion();

   ###instance hierarchies
   &printHierarchies();

   ###MaxEC
   &printMaxEc();
   
   print OUTFILE "#######################################################\n\n";

   ###Write the individual files into OUTFILE
   for $if (sort keys %initfiles) {
      &copyInitFile($if);   
   }


   close OUTFILE;
}


###################################################
sub printHeader {

   my $if;
   my $date = `date`;
   chomp $date;

   print OUTFILE "#######################################################\n";
   print OUTFILE "#This initfile was merged by $progName on $date.\n";
   print OUTFILE "#It is made up of the following initfiles:\n"; 

   for $if (sort keys %initfiles) {
      print OUTFILE "#    $initfiles{$if}{PATH}\n";   
   }

   print OUTFILE "#\n#Comment lines and blank lines were stripped from the initfiles before merging\n";
   print OUTFILE "#######################################################\n";
}

####################################################
sub printVersions {
	
   my $if;
   my $out;
   
   $out = "\nVersions =  ";
   for $if (sort keys %initfiles) {   
     $out .= "$if:$initfiles{$if}{VERSION}, ";      
   }
   $out =~ s/\,\s+$//g;
   
   
   print OUTFILE "$out\n\n";
   
}


####################################################
sub printHierarchies {
   my %allHiers;
   my @hiers;
   my $hier;
   my $if;

   for $if (sort keys %initfiles) {

      if (exists $initfiles{$if}{HIERARCHIES}) {
         @hiers = split(',', $initfiles{$if}{HIERARCHIES});

         foreach $hier (@hiers) {
            $hier = uc $hier;

            #add it to the master list if not already there
            if (not exists $allHiers{$hier}) {
               $allHiers{$hier} = $hier;
            }            
         }

      }  
   }

   if (keys(%allHiers) > 0) {
      my $out =  "\nInstanceHierarchy = ";
      for $hier (sort keys %allHiers) {
         $out .=  "$allHiers{$hier},";
      }
      $out =~ s/\,$//; #take out the last ,
      print OUTFILE "$out\n";
   }


}

################################
sub printMaxEc {
   my $if;
   my $maxec;

   for $if (sort keys %initfiles) {

      if (exists $initfiles{$if}{MAXEC}) {

         if (not defined $maxec) {
            $maxec =  $initfiles{$if}{MAXEC}; 	   
         }
         else {
            if ($maxec ne $initfiles{$if}{MAXEC}) {  	     
               die "MaxEC lines must match if they are defined in a file!\n";  	     
            }
         }
      }
   }
   if (defined $maxec) {
      print "\nMAXEC of merged file = $maxec\n";
      print OUTFILE "\nMaxEc = $maxec\n\n";
   }

}

##################################
sub  printSyntaxVersion {
   my $if;
   my $version;

   for $if (sort keys %initfiles) {

      if (not defined $version) {
         $version = $initfiles{$if}{SYNTAXVERSION};
      } else {
         if ($version ne $initfiles{$if}{SYNTAXVERSION}) {
            die "ERROR: Syntax Versions must match in all files!\n";   
         }
      }   
   }

   if (defined $version) {

      print "\nSyntax Version from member files = $version\n";
      print "Syntax Version of merged file = $MERGE_VERSION\n";
      print OUTFILE "SyntaxVersion = $MERGE_VERSION\n";
   }
   else {
      die "No syntax versions defined in any file!\n";
   }
}


##################################
sub copyInitFile {

   my $if = shift @_;

   open INITFILE, $initfiles{$if}{PATH} or die "Could not open $initfiles{$if}{PATH}\n";

   print "Writing section $initfiles{$if}{PATH}\n";

   print OUTFILE "\n####Start initfile $initfiles{$if}{PATH}####\n\n";

   while (<INITFILE>) {

      next unless (/\S/);             #something besides whitespace
      next if (/^\s*#/);              #skip comments
      next if (/SyntaxVersion/i);     #skip syntax version
      next if (/MaxEc/i);             #skip maxec
      next if (/InstanceHierarchy/i); #skip instance hierarchy
      next if (/\$Id/i);              #skip CVS version      
            
      print OUTFILE "$_";
   }

   print OUTFILE "\n#This next line was inserted by this program to allow\n";
   print OUTFILE "#the compiler to scope DEFINES.\n";
   print OUTFILE "END_INITFILE\n";

   print OUTFILE "\n####End initfile $initfiles{$if}{PATH}####\n\n";

   close INITFILE;
}
