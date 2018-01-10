package Archive::WARC::Record;
use strict;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Carp qw(croak);
use HTTP::Headers;
use IO::Uncompress::AnyUncompress ();

sub new( $class, %args ) {
    bless \%args => $class;
};

# Taken from HTTP::Message, which isn't suited to subclassing
sub parse_headers($self, $str) {
    my @hdr;
    while (1) {
        if ($str =~ s/^([^\s:]+)[ \t]*: ?(.*)\n?//) {
            push(@hdr, $1, $2);
            $hdr[-1] =~ s/\r\z//;
        }
        elsif (@hdr && $str =~ s/^([ \t].*)\n?//) {
            $hdr[-1] .= "\n$1";
            $hdr[-1] =~ s/\r\z//;
        }
        else {
            $str =~ s/^\r?\n//;
            last;
        }
    }
    local $HTTP::Headers::TRANSLATE_UNDERSCORE;
    HTTP::Headers->new(
        @hdr
    );
}

# This should be more robust against mal(icious|formed) WARC files
sub read($self,$fh, %options) {
    $self= ref $self ? $self : $self->new();

    # Headers longer than that are not interesting
    $options{ max_body_size } //= 1024*1024;
    $options{ strict }= 1;

    binmode $fh; # Should not be necessary, but...
    
    local $/= "\r\n";
    my $version= <$fh>;
    use Data::Dumper;
    local $Data::Dumper::Useqq= 1;
    $version=~ m!^WARC/[01]\.\d+\r\n$!
        or croak "Not a WARC buffer: " . Dumper $version;
    $self->{version}= $version;
    
    
    local $/= "\r\n\r\n";
    my $h= <$fh>;
    my $headers= $self->parse_headers($h);
    $self->{ _headers }= $headers;
    # verify headers
    my $len= $headers->content_length;
    if( ! defined $len) {
        use Data::Dumper;
        warn Dumper $headers;
        croak "Invalid WARC header: No Content-Length defined in <<$h>>";
    };
    my $max_len; # how many bytes will we read in at max?
    if( $options{ strict }) {
        $max_len= $options{ max_body_size } || $len;
    } else {
        $max_len= $options{ max_body_size };
    };

    #print sprintf "Length of headers: %d\n", length $h;
    
    # We should allow for uncompressed files here too...
    if( $options{ read_body }) {
        my $read= 0;
        my $body;
        while( $max_len > $read ) {
            my $bytes_read= read( $fh, $body, $max_len, length $body );
            
            last if eof($fh);
            $read+= $bytes_read;
        };
        
        # Also read+skip the CRLF+CRLF at the end
        if( ! eof($fh) ) {
            my $trailer= read($fh, my $buf, 4);
            if( $options{ strict } and 4 != $trailer ) {
                croak sprintf "Invalid WARC trailer - only read %d bytes instead of %d", $trailer, 4;
            };
        };

        # If we didn't read to the end, we're likely not complete
        $self->{body_complete}=    $max_len < $read
                                || eof($fh);
        
        # https://lists.gnu.org/archive/html/bug-wget/2012-11/msg00023.html
        # The Content-Length of files produced by (some versions of)
        # wget is invalid...
        # This is only valid for compressed files!
        # For others, wind forward until the next m!^WARC/1.0! record!
        local $/ = \(1024*1024);
        1 while <$fh>;
        
        $self->{ _body }= $body;
    } else {
        #print sprintf "Skipping %d bytes for body\n", $len;
        # Jump to EOF
        # IO::Uncompress will read+decompress anyway :-/
        # This is only valid for compressed files!
        # For others, wind forward until the next m!^WARC/1.0! record!
        local $/ = \(1024*1024);
        1 while <$fh>;
    };

    #if( 'warcinfo' eq $self->{_headers}->header('WARC-Type')) {
    #    print "[[$h]]";
    #    print "[[$self->{_body}]]";
    #};
    
    # Parse the HTTP headers and payload, at least
    # to some extent
    # Also provide the URL

    $self
}

sub body( $self, $fh ) {
    if( ! $self->{body_complete}) {
        # Need to fill in the body
        $self->read($fh, read_body => 1 );
    };
    $self->{_body}
}

1;