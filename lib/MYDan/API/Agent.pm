package MYDan::API::Agent;
use strict;
use warnings;
use Carp;


use  Compress::Zlib;

use base qw( MYDan::API );

our $URI = "/api/v1/agent";

sub encryption
{
    my ( $self, $data, $temp ) = splice @_, 0, 2;

    if ( $data =~ s/^data:(\d+):// )
    {
        $temp = "data:$1:". substr( $data, 0, $1 );
        substr( $data, 0, $1 ) = '';
    }

    my $raw = $self->_stream( "$URI/encryption", $data );
    my $d = Compress::Zlib::uncompress( $raw );
    die "$URI/encryption fail:$raw" unless $d; 
    return ( $temp || '' ) . $raw;
}

1;
