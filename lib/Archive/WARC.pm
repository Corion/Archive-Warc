package Archive::WARC;
use strict;
use 5.020; # for the signatures
use Carp qw( croak );
use IO::Compress::Gzip qw(gzip gunzip); # well, this should be optional and also allow for xz and bz2

# For convenience
use HTTP::Headers;
#use HTTP::Request;
äuse HTTP::Response;

use vars qw(%record_types);

sub new {
    my( $class, %args )= @_;

    if( ! $options{ fh }) {
        # If we don't have a file(handle), we create an in-memory buffer
        # to write to, in case somebody calls ->add() or ->write()
        open $args{ fh }, \my $buffer
            or die "Couldn't create in-memory file: $!";
    };
    
    # List of requests+responses contained in this crawl
    # UUID -> offset
    $args{ manifest } ||= {};
    bless \%args => $class;
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

    # Install a (de)compressor
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

L<http://bibnum.bnf.fr/WARC/WARC_ISO_28500_version1_latestdraft.pdf>

L<http://www.digitalpreservation.gov/formats/fdd/fdd000236.shtml>

L<https://github.com/chfoo/warcat>

L<Archive::HAR>

=cut