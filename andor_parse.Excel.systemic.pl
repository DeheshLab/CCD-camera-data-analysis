#!/usr/bin/perl
#andor_parse.Excel.systemic.pl by Geoff Benn

#This program is basically the same as andor_parse.Excel.pl, except that it is designed to deal
#with having 2 regions of interest per plant (used when systemic Luciferase expression is of interest).
#The two ROI are averaged and then placed into an array of arrays, which is then processed as in andor_parse.Excel.

#This program is designed to parse output from the Andor Solis program and produce a tab-delimited file which can then be opened in Excel to make a graph

#Input file requirements:
#Do the following in Excel
#In cell A1, type "Time" and put your time values starting in C1
#in cell A2, type "TRT1" and put the name of your first treatment in A2 - note: YOUR TRT NAME CANNOT START WITH A NUMBER!!
#paste the entire Andor sheet for this treatment in cell A4
#following your data, there must be the text "ROI" in column B. This is normally present at the end of set of data produced by Andor Solis
#If you wish to average multiple experimental reps together, simply don't include "ROI" in column B between the reps
#below this data, type "TRT1" in a cell in column A and then put your name for the next treatment in column B, next to it
#paste the whole Andor sheet below it
#repeat until you have all treatments on the sheet

#Optional:
	#if you have multiple genotypes, before pasting in the data, type "Geno" in colA and then type your genotype in colB
	#if you have a second treatment, type TRT2 in colA and then type the treatment in colB
#save the excel sheet as a tab-delimited file
#run andor_parse.Excel.pl on the file from the terminal (i.e. "perl andor_parse.Excel.systemic.pl CCD.data.txt")
#this will produce an output file in the same directory as the input file
#open the file with Excel and make your graph


use strict; use warnings;

my $file = $ARGV[0];

open(IN, "<$file");
my $TRT1 = "null";					
my $Geno = "null";
my @time = "null";
my @lineholder = ();				#this is an array of arrays
my @stderr = ();
open(OUT, ">$file.Andor.txt");

while (<IN>) {
	chomp;
	my @line = split(/\t/);			#creates @line to hold line, as delineated by tabs

#this section collects the time values, stores them in an array, and prints them
	if ($line[0] =~ m/Time/) {		#finds a line with "Time" in column 1
		@time = @line;
		shift (@time);
		shift (@time);
		my $timeout = join('	',@time);
		print OUT "time\t\t$timeout\n";
		}

#this section collects the names of the treatments
	if ($line[0] =~ m/TRT1/) {
		$TRT1 = $line[1];
		}

	if ($line[0] =~ m/Geno/) {
		$Geno = $line[1];
		}
#this section calculates the mean and standard errors for each treatment - the program knows that it is done reading
#in a particular treatment due to the presence in the .tab file of "ROI" in column B, from the ROI coordinates section
#that Andor produces at the end of each chunk of data
	if ($line[1] =~ m/ROI/) {
		my $length = @time;		#number of timepoints
		my $points = @time;
		my $i = 0;		#position in data array
		my $x = 0;		#position in array of arrays
		my @averages = ();
		

#This section averages the two values for systemic expression in each plant
		my $d = 0;
		my $c = 0;
		my $m = @lineholder;
		my @sysavg = ();				#this is the array of arrays that holds the average ROI value for each plant
		while ($d < $m-1) {
			my @avgholder = ();
			$c = 0;
			while ($c < $length) {
				my $average = ($lineholder[$d][$c] + $lineholder[$d+1][$c])/2;
				push (@avgholder, $average);
				$c++
			}
			push (@sysavg, [@avgholder]);
			$d = $d + 2;
		}
	

#this section calculates the mean for each time point. This is done using an array of arrays, where the full
#time series for each ROI is an array. Each ROI array is then stored in the $lineholder array (this actually happens 
#in the m/Mean/ loop). Ta calculate the means, the array of arrays is looped through each ROI array, calculating the
#mean for each timepoint as it goes 
		my $n = @sysavg;		#number of data points
		while ($i < $length) {
			my $avg = 0;
			$x = 0;
			while ($x < $n) {
				unless ($sysavg[$x][$i] =~ m/NA/) {
				$avg = $avg + $sysavg[$x][$i];
				}
				$x++
			}
			$avg = ($avg/$n);
			push (@averages, $avg);
			$i++
		}

#this section calculates the standard errors, using the same principles as the averages section
		my $a = 0;
		my $b = 0;
		my @stderrors = ();
		while ($a < $length) {
			my $std1 = 0;
			$b = 0;
			while ($b < $n) {
				unless ($sysavg[$b][$a] =~ m/NA/) {
				my $std2 = $sysavg[$b][$a] - $averages[$a];
				$std2 = $std2 ** 2;
				$std1 = $std1 + $std2;
				}
				$b++;
			}
			$std1 = $std1/($n-1);
			$std1 = sqrt($std1);
			my $stderr = $std1/(sqrt($n));
			push (@stderrors, $stderr);
			$a++
		}

#this prints out the means and standard errors
		my @names = ();
		my $name;
		if ($Geno ne "null") {
			push (@names, $Geno);
			}

		if ($TRT1 ne "null") {
			push (@names, $TRT1)
			}
		$name = join('.',@names);	
		my $avgout = join('	',@averages);				#turns @averages into string for printing
		print OUT "mean\t$name\t$avgout\n";				
		my $stderrout = join('	',@stderrors);
		push (@stderr, "StdErr\t$name\t$stderrout\n");
		@lineholder = ();
	}

#this section collects the means from all of the ROI lines and stores them as arrays in @lineholder
	if ($line[1] =~ m/Mean/){
		shift(@line);
		shift(@line);
		push (@lineholder, [@line]);
		}	
}

print OUT "\n";

foreach (@stderr) {
	print OUT;
	}

close OUT;
close IN;