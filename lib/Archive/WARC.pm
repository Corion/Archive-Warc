package Archive::WARC;
use strict;
use warnings;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Carp qw( croak );

use IO::Uncompress::AnyUncompress;


=head1 NAME

Archive::Warc - read and write Web ARChive (WARC) files

=head1 NOTE

This is a work in progress, not yet fit for release on CPAN.

=head1 SEE ALSO

L<WARC> - a module that is actually in use

=cut

our $VERSION = 0.01;

# For convenience
#use HTTP::Headers;
#use HTTP::Request;
#use HTTP::Response;

our %record_types;

sub new {
    my( $class, %options )= @_;

    if( ! $options{ fh }) {
        # If we don't have a file(handle), we create an in-memory buffer
        # to write to, in case somebody calls ->add() or ->write()
        open $options{ fh }, \my $buffer
            or die "Couldn't create in-memory file: $!";
    };

    # List of requests+responses contained in this crawl
    # UUID -> offset
    $options{ manifest } ||= {};
    bless \%options => $class;
}

sub add_record {
};

sub verify_warc_header( $self, $header ) {
    # Check valid WARC-Type
    # valid WARC-Record-ID
    # valid Content-Length
    # WARC-Date
    # Content-Type must be application/http; msgtype=request
    # or                   application/http; msgtype=response
    # validate SHA1 (or whatever we get)
}

sub parse_version( $self ) {

}

sub read( $self, %options ) {
    if( $options{ filename }) {
        open $options{ fh }, '<', $options{ filename }
            or croak "Couldn't read archive '$options{ filename }': $!";
        binmode $options{ fh };
    };
    my $fh = delete $options{ fh };

    # Support any compression
    my $ofs = tell($fh);
    my $reader= IO::Uncompress::AnyUncompress->new( $fh );
    $reader->binmode();
    my %requests;

    while( ! $reader->eof ) {
        # Save the offset in the compressed file of this part
        # Found by nasty source-diving
        my $r= Archive::WARC::Record->read( $reader, read_body => 1, offset => $ofs );
        #print $r->{_headers}->as_string;
        #print sprintf "Header type: %s\n", $r->{_headers}->header('WARC-Type');
        #print sprintf "Header type: %s\n", $r->{_headers}->header('Content-Type');
        #print sprintf "UUID: %s\n", $r->{_headers}->header('WARC-UUID');

        #print $r->headers->as_string;

        #print sprintf "Content-Length according to WARC     : %d\n", $r->{_headers}->content_length;
        if( defined $r->_body) {
            #print sprintf "Content-Length according to read data: %d\n", length $r->_body;
            my $url = $r->headers->header('WARC-Target-URI');
            my $rid = $r->headers->header('WARC-Record-ID');
            my $requestid = $r->headers->header('WARC-Concurrent-To');
            print $r->headers->header('WARC-Type'), "\n";
            print $r->headers->as_string;
            if( $r->is_request ) {
                use HTTP::Request;
                my $request = HTTP::Request->parse($r->_body());
                $requests{ $rid } = $request;
                print ">>> " . $request->uri, " ($rid)\n";
            };
            if( $r->is_response) {
                my $request = delete $requests{ $requestid }
                    or die "No request found for $rid";
                print "Found <$rid>\n";
                use HTTP::Response;
                my $response = HTTP::Response->parse($r->_body());
                #    # Fix up the appropriate request
                $response->request( $request );
            };
        };

        #if( 'text/plain' eq $r->headers->content_type ) {
        #    print "----\n";
        #    print $r->_body;
        #    print "----\n";
        #};

        # If we have more, read them:
        $reader->nextStream();
        $ofs= tell($fh) - length( $reader->trailingData );
        #warn sprintf "File offset of last block %d\n", $ofs;
    };
}

sub write( $self, %options ) {
    if( $options{ filename }) {
        open $options{ fh }, '>', $options{ filename }
            or croak "Couldn't read archive '$options{ filename }': $!";
        binmode $options{ fh };
    };
    croak "Not implemented yet";
};

# Shorthand to add a request (headers+body)
# Assumes a HTTP::Request duck-type
# Returns the UUID assigned to this request
sub add_request( $self, $request ) {
    my $uuid= $self->new_uuid;
    #$self->add_request_headers( headers => $request->headers, uuid => $uuid );
    #$self->add_request_body( body => $request->body, uuid => $uuid );
    $uuid
};

# Shorthand to add a response (headers+body)
# Assumes a HTTP::Response duck-type
sub add_response( $self, $response, $uuid ) {

    if( ! $uuid ) {
        croak "Need a UUID for a response!";
    };
    #$self->add_response_headers( headers => $response->headers, uuid => $uuid );
    #$self->add_response_body( body => $response->body, uuid => $uuid );
};

# Archive::Extract API
sub files {
}

sub archive( $self ) {
    $self->{file}
}

sub type( $self ) {
    ref $self
}

1;


=head1 SEE ALSO

L<https://github.com/iipc/warc-specifications/blob/gh-pages/specifications/warc-format/warc-1.1/index.md>

L<http://bibnum.bnf.fr/WARC/WARC_ISO_28500_version1_latestdraft.pdf>

L<http://www.digitalpreservation.gov/formats/fdd/fdd000236.shtml>

L<https://github.com/chfoo/warcat>

L<https://github.com/machawk1/warcreate>

L<Archive::Har>

=cut
