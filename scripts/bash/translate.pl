#!/usr/bin/perl
#
# Translate backtraces found in debug log
# Copyright 2012-2012 Pierre Schweitzer <pierre@reactos.org>
#
# Released under GNU GPL v2 or any later version.

my $SYMBOL_STORE = "./symbols";
my $ADDR2LINE = "i686-w64-mingw32-addr2line";
my $CPPFILT = "c++filt";

# Input: one log is required
if ($#ARGV != 0)
{
	print "Input file is required\n";
	exit;
}

my $in_bt = 0;
my $address;
my $trans;

open(my $log_file, "<", $ARGV[0]) or die "Can't open $ARGV[0]: $!";
while (<$log_file>)
{
	# Check if we enter in backtrace
	unless ($in_bt)
	{
		# Output line
		print;
		next unless (/^Eip:/);

		# Eip: has been found, so yes
		$in_bt = 1;
		next;
	}

	# Check if we leave backtrace
	if (/^kdb:>/)
	{
		# Output line and mark out
		print;
		$in_bt = 0;
		next;
	}

	# Now, we're in backtrace and we have to translate
	unless (/^<(.+):([a-fA-F0-9]+)(.*)>/)
	{
		# Keep printing even if not valid
		print;
		next;
	}

	# Move to .text
	$address = sprintf("%x", (hex($2) - 4096));
	# And translate
	$trans = `$ADDR2LINE -ip -j .text -f -e $SYMBOL_STORE/$1.dbg $address | $CPPFILT`;

	# Print back fixed line
	print "<$1:$2 $trans>\n";
}

close $log_file or die "Can't close $ARGV[0]: $!";
