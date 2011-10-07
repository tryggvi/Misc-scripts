#!/usr/bin/perl
# 
# Bulk migrate of Xen servers
#
# Author: Tryggvi Farestveit <tryggvi@ok.is>
#
# License: GPLv2
#
# Examples:
#	Migrate all vm from this node to xenserver-2:
#		xenmigrate -t xenserver-2 -a
#	Migrate only node1,webserver2 and mysql01 to xenserver-2:
#		xenmigrate -t xenserver-2 -m node1,webserver2,mysql01
#
use strict;

# Settings
my $virsh = "/usr/bin/virsh";
my $xm = "/usr/sbin/xm";

### Do not edit below ###
use Getopt::Std;
our ($opt_h, $opt_v, $opt_t, $opt_m, $opt_a, $opt_s);
getopts('hvm:t:as');

if($opt_v || $opt_h){
	print "xenmigrate [OPTIONS] ...\n\n";
	print "Optional options:\n";
	print "  -t [host]\tMigrate to xen server\n";
	print "  -m [vms]\tVirtual machines to migrate comma seperated\n";
	print "  -a\t\tVMigrate all nodes\n";
	print "  -s\t\tSimulate (do not execute migrate)\n";
	print "\n\n";
	print "Example:\n";
	print "\tMigrate node1, webserver2 and mysql01 to Xen (dom-0) xenserver-2\n";
	print "\txenmigrate -t xenserver-2 -m node1,webserver2,mysql01\n";
	print "\n";
	exit;
}

if(!$opt_t){
	print "Error: -t missing. See -h\n";
	exit;
} elsif (!$opt_m && !$opt_a){
	print "Error: -m or -a missing. See -h\n";
	exit;
}

my $host = $opt_t;
my @nodes = split(",", lc($opt_m));

if($opt_s){
	print "Simulation on. Migration will not be performed.\n\n";
}

my %NodesToMove;
my $countA=0;
for(my $i=0; $i < scalar(@nodes); $i++){
	$NodesToMove{$nodes[$i]} = 1;
	$countA=$i;
}
$countA++;

print "Do you want to migrate these nodes to $host:\n";
my @vms = GetRunning();
my $countB=0;
my %move;
for(my $z=0; $z < scalar(@vms); $z++){
	my $id = $vms[$z]{id};
	my $hostname = $vms[$z]{hostname};
	my $hostname_lc = $vms[$z]{hostname_lc};
	if($NodesToMove{$hostname_lc} || $opt_a){
		$NodesToMove{$hostname_lc} = 0;
		$countB++;
		$move{$hostname}=1;
		print "\t$hostname\n";
	}
}

if($countA > $countB){
	print "\nNode not found:\n";
	for(my $i=0; $i < scalar(@nodes); $i++){
		if($NodesToMove{$nodes[$i]}){
			print "\t$nodes[$i]\n";
		}
	}
}

if($countB > 0){
	print "\nDo you want to execute migration: [n] ";
	my $input = <STDIN>;
	chomp($input);
	$input = lc($input);
	if($input eq "y" || $input eq "yes"){
		while ( my ($vm, $value) = each(%move) ) {
			my $cmd = "$xm migrate -l $vm $host";
			print "$cmd\n";
			if(!$opt_s){
				system($cmd);
			}
		}
	} else {
		print "Canceled\n";
		exit;
	}
}


sub GetRunning(){
	open(V, "$virsh list|");
	my @vms;
	my $i=0;
	my $start=0;
	while(<V>){
		chomp($_);
		split;

		if(!$_[0]){
			$start=0;
		}

		if($start){
			my ($id, $vm, $state) = split;
			$vms[$i] = ({
				"id" => $id,
				"hostname" => $vm,
				"hostname_lc" => lc($vm)
			});
			$i++;
		}

		if($_[0] eq "0"){
			$start=1;
		} 

	}
	close(V);
	return @vms;
}
