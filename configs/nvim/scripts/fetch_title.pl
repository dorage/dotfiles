#! /usr/bin/perl
use HTTP::Tiny;
use LWP::Simple;
# LWP::Protocols::https | it needs to request on 'https'

# get first argument
my $url = shift(@ARGV);
$content = get($url);
$content =~ /\<title\>(.*?)\<\/title\>|<meta [^>]*property=[\"']og:title[\"'] [^>]*content=[\"']([^'^\"]+?)[\"'][^>]*>/;

print "Untitled" if (! defined $content);
print "$1"
