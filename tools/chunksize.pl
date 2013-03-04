#!/usr/bin/perl
# Analyse size of files in directory and print out number of files in each chunk size.
# 
# Helpful when deciding what chunk size to use when creating raid.
# 
# GPLv2
# 
# Author: Tryggvi Farestveit <tryggvi@ok.is>
#
use strict;

## Settings
my $chunk_min = 16; # min chunk size (KB)
my $chunk_max = 512; # max chunk size (KB)

#####
my @chunks;
sub CreateChunkArr(){
	my $chunk=$chunk_max;
	my @arr;
	my $i=0;
	$arr[$i] = $chunk;
	$i++;
	while($chunk > $chunk_min){
		$chunk = $chunk / 2;
		$arr[$i] = $chunk;
		$i++;
	}

	my @arr_rev = reverse @arr;
	return @arr_rev;
}

@chunks = CreateChunkArr();

my $dir = shift;

if(!$dir){
	print "$0 [dir]\n";
	exit;
}

my %results;
open(E, "find $dir -type f|");
while(<E>){
	chomp($_);

	my $filename = $_;
	my @stat = stat("$filename");
	my $size = int($stat[7] / 1024);

	if($size > $chunk_max){
		$results{$chunk_max} = $results{$chunk_max} + 1;
	} elsif($size < $chunk_min){
		$results{$chunk_min} = $results{$chunk_min} + 1;
	} else {
		for(my $i=0; $i < scalar(@chunks); $i++){
			my $current = $chunks[$i];
			my $next = $chunks[$i+1];
			if($current eq $chunk_max){
				$results{$current} = $results{$current} + 1;
				last;
			} else {
				if($size >= $current && $size < $next){
					$results{$current} = $results{$current} + 1;
					last;
				}
			}
		}
	}
}
close(E);

my $i=1;
my $recommend;
my $total;
foreach my $key (sort { $results {$b} <=> $results {$a}} keys %results ){
	if($i eq 1){
		$recommend = $key;
	}
	my $x = $results{$key};
	$total = $total + $x;
	print "$i. $key KB - $results{$key} files\n"; 
	$i++;
} 

print "Total $total files\n";

print "\nRecommended chunk size is: $recommend KB\n";

