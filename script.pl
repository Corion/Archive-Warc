#!perl -w
use strict;
use Archive::WARC::Record;
use IO::Uncompress::Gunzip;

my($fn)= @ARGV;

open my $fh, '<', $fn
    or die "Couldn't read '$fn': $!";
binmode $fh;

# Support any compression
my $reader= IO::Uncompress::AnyUncompress->new( $fh );
#my $reader= IO::Uncompress::Gunzip->new( $fh );
$reader->binmode();

while( ! $reader->eof ) {
    my $r= Archive::WARC::Record->read( $reader, read_body => 1 );
    #print $r->{_headers}->as_string;
    #print sprintf "Header type: %s\n", $r->{_headers}->header('WARC-Type');
    #print sprintf "Header type: %s\n", $r->{_headers}->header('Content-Type');
    #print sprintf "UUID: %s\n", $r->{_headers}->header('WARC-UUID');
    print $r->{_headers}->as_string;
    #print sprintf "Content-Length according to WARC     : %d\n", $r->{_headers}->content_length;
    if( defined $r->{body}) {
        print sprintf "Content-Length according to read data: %d\n", length $r->{_body};
    };
    
    if( 'text/plain' eq $r->{_headers}->content_type ) {
        print "----\n";
        print $r->{_body};
        print "----\n";
    };
    
    # If we have more, read them:
    $reader->nextStream();
};
