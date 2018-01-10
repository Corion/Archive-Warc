package Archive::WARC::Header;
use strict;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Carp qw( croak );

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

sub read($self,$fh) {
    local $/= "";
    my $headers= $self->parse_headers(<$fh>);
    my $len= $headers->{"Content-Length"};
    if( ! defined $len) {
        croak "Invalid WARC header: No Content-length defined";
    };
    read( $fh, my $body, $len );
    $self->{ _headers }= $headers;
    $self->{ _body }= $body;
    
    1
}

sub as_string($self) {
    $self->{headers}->as_string()
}

1;