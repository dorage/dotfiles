#! /usr/bin/perl
use strict;
use warnings;

# add new perl script on the directory

use Cwd;
use File::Basename;

my $dirname = dirname(__FILE__);
my $filename = shift(@ARGV);

# check file exists
exit print "😥 $filename.pl exists!\n" if -e "$filename.pl";

# write file
{
 open my $fh, '>', "$filename.pl";
 # write body
 print {$fh} `cat $dirname/boilerplates/perl-basic`;
 # make executable
 print `chmod \+x $filename.pl`;
 close $fh;
}

 print "📝 '$filename' has benn cretaed!"
