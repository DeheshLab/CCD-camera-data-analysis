#!/usr/bin/perl
#Andor_parseR.pl by Geoff Benn

# This program parses data files from Andor Solis and transforms them into a format that can be used in R

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

# It is important to note that the values printed out at "Early" and "Ninety" correspond to the camera settings
# I was using when I wrote this program (10' between images). Therefore you should see what timepoint these
# outputs correspond to in your data. The "Area" output is the area under the curve from the 2nd image to the
# 26th image. If your data has fewer than 26 images, then this part of the code will cause an error. If this
# is the case, then comment out the while loop that calculates the area (starting around line 63), by placing
# a "#" at the start of each line in the loop.

use strict; use warnings;

my $file = $ARGV[0];

open(IN, "<$file");
my $TRT1 = "null";
my $EXP = "null";
my $Geno = "null";
my $TRT2 = "null";
my $Area = "null";
my $Early = "null";
my $Peak = "null";
my @time = "null";
open(OUT, ">$file.R.txt");
print OUT "EXP\tTRT1\tGeno\tTRT2\tArea\tEarly\tNinety\n";		#creates the header in output file

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
	if ($line[0] =~ m/Geno/) {		#holds the current genotype
		$Geno = $line[1];
		}
	if ($line[0] =~ m/TRT2/) {		#holds the current second treatment
		$TRT2 = $line[1];
		}
		
	if ($line[1] =~ m/Mean/) {
		$Early = $line[4];			#holds value for the 3rd image (30 minutes with my settings)
		$Peak = $line[11];			#holds value for the 10th image (90 minutes with my settings)
		my $i = 3;
		my $j = 4;
		$Area = 0;					#holds area for current row
		while ($i < 28) {			#this loop calculates area under curve for current row for the 2nd through 26th image (10'-5hrs w. my settings)
			my $height = abs($time[$j] - $time[$i]);						#height of trapazoid
			my $trap = ((($line[$i] + $line[$j]) * $height) / 2);	#calculates area of trapezoid for current data points
			$Area = $Area + $trap;		#adds area of current trapezoid to total for the row
			$i++;
			$j++;
		}
		print OUT "$EXP\t$TRT1\t$Geno\t$TRT2\t$Area\t$Early\t$Peak\n";
	}
}

close IN;
close OUT;