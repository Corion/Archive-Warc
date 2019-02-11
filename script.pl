#!perl -w
use strict;
use Archive::WARC::Record;
use Archive::WARC;

my($fn)= @ARGV;


my $archive= Archive::WARC->read( filename => $fn );
