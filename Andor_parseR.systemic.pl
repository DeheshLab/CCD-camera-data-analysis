#!/usr/bin/perl
#Andor_parseR.systemic.pl by gkbenn

# This program parses data files from Andor Solis and transforms them into a format that can be used in R.
# This is designed to be used with data files that have two ROI per plant. The program reports the average
# of the two ROI at the timepoint designated in the code (90' with my settings)

# To prepare the file for analysis, you need to have a line containing your time values
# write "Time" in A1 and then paste your time values starting in C3 (so that they line up with the corresponding data points)
# Above each set of data for a given treatment, write "TRT1" in column A and then rite the treatment name next to it in column B. 
# Likewise for data from different experiments, type EXP in A and then the experiment code in B. 
# If you have different genotypes, you can specify this by writing "Geno" in column A and then writing the genotype in column B. 
# A second treatment may be specified by typing TRT2 in column A and typing the treatment in column B.
# Then paste in the raw data from Andor for that treatment/Genotype/Experiment.
# Repeat until all of your data is in one sheet. Save the sheet as a tab-delimted text file
# Run this script in the terminal by calling "perl Andor_parseR.pl Your.Data.txt"
# An output file will be produced in the same directory. This can be opened in Excel for further
# modification or can be directly imported into R.

# It is important to note that the values printed out at "Ninety" correspond to the camera settings
# I was using when I wrote this program (10' between images). Therefore you should see what timepoint these
# outputs correspond to in your data.

use strict; use warnings;

my $file = $ARGV[0];

open(IN, "<$file");
my $TRT1 = "null";
my $EXP = "null";
my $Geno = "null";
my $TRT2 = "null";
my $Peak = "null";
my $counter = 0;
my $avg = 0;
my $print = 0;
my @time = "null";
open(OUT, ">$file.R.txt");
print OUT "EXP\tTRT1\tGeno\tTRT2\tNinety\n";		#creates the header in output file

while (<IN>) {
	chomp;
	my @line = split(/\t/);			#creates @line to hold line, as delineated by tabs
	if ($line[0] =~ m/Time/) {		#finds a line with "Time" in column 1
		@time = @line;				#holds time values
		}
	if ($line[0] =~ m/TRT1/) {		
		$TRT1 = $line[1];			#holds current treatment name
		}
	if ($line[0] =~ m/EXP/) {
		$EXP = $line[1];			#holds current experiment name
		}
	if ($line[0] =~ m/Geno/) {		#holds current genotype
		$Geno = $line[1];
		}
	if ($line[0] =~ m/TRT2/) {		#holds current second treatment
		$TRT2 = $line[1];
		}
		
	if ($line[1] =~ m/Mean/) {
		if($counter == 0) {
			$Peak = $line[11];			#holds value from the 10th image (90' with my camera settings)
			$print = 0;					#makes the code skip the next if statement
		}
		if($counter == 1) {
			$avg = ($Peak + $line[11])/2;					#calculates average of the two ROI
			print OUT "$EXP\t$TRT1\t$Geno\t$TRT2\t$avg\n";
			$counter = 0;
			$print = 1;
		}
		if($print == 0){				
			$counter++;					#makes data enter second if statement on the next run-through
		}
	}
}

close IN;
close OUT;