package WebService::Prowl;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use LWP::UserAgent;
use Crypt::SSLeay;
use Carp qw(croak);

my $API_BASE_URL = 'https://prowl.weks.net/publicapi/';

BEGIN {
    @WebService::Prowl::EXPORT = qw( LIBXML );
    if ( eval { require XML::LibXML::Simple } ) {
        *{WebService::Prowl::LIBXML} = sub() {1};
    }
    else {
        require XML::Simple;
        *{WebService::Prowl::LIBXML} = sub() {0};
    }
}

sub new {
    my $class  = shift;
    my %params = @_;
    my $apikey = $params{'apikey'};
    croak("apikey is required") unless $apikey;
    return bless {
        apikey => $params{'apikey'},
        ua    => LWP::UserAgent->new( agent => __PACKAGE__ . '/' . $VERSION ),
        error => '',
    }, $class;
}

sub ua { $_[0]->{ua} }

sub error { $_[0]->{error} }

sub add {
    my ( $self, %params ) = @_;
    my @params = qw/priority application event description/;
    my $req_params = +{ map { $_ => delete $params{$_} } @params };

    croak("event name is required")       unless $req_params->{event};
    croak("application name is required") unless $req_params->{application};
    croak("description is required")      unless $req_params->{description};

    $req_params->{priority} ||= 0;

    croak("priority must be an integer value in the range [-2, 2]")
        if ( $req_params->{priority} !~ /^-?\d+$/
        || $req_params->{priority} < -2
        || $req_params->{priority} > 2 );

    my $url = $API_BASE_URL . 'add?apikey=' . $self->{apikey} . '&';
    $url .= join( '&', map { $_ . '=' . _ue( $req_params->{$_} ) } @params );

    $self->_send_request($url);
}

sub verify {
    my ($self) = @_;

    my $url = $API_BASE_URL . 'verify?apikey=' . $self->{apikey};
    $self->_send_request($url);
}

sub _ue {
    my $str = shift;
    $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $str;
}

sub _send_request {
    my ( $self, $url ) = @_;
    my $res = $self->{ua}->get($url);
    my $data;
    if (LIBXML) {
        $data = XML::LibXML::Simple->new->XMLin( $res->content );
    }
    else {
        $data = XML::Simple->new->XMLin( $res->content );
    }

    if ( $res->is_error ) {
        $self->{error} =
              $data->{error}
            ? $data->{error}{code} . ': ' . $data->{error}{content}
            : '';
        return;
    }
    return 1;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::Prowl -

=head1 SYNOPSIS

  use WebService::Prowl;

=head1 DESCRIPTION

WebService::Prowl is a interface to Prowl Public API

=head1 SYNOPSIS

This module aims to be a implementation of a interface to the Prowl Public API (as available on http://forums.cocoaforge.com/viewtopic.php?f=45&t=20339)

    use WebService::Prowl;
    my $ws = WevService::Prowl->new(apikey => 40byteshexadecimalstring);
    $ws->verify || die $ws->error();
    $ws->add(application => "Favotter App",
             event       => "new fav",
             description => "your tweet saved as sekimura's favorite")) {
    }

=head1 METHODS

=over 4

=item new(apikey => 40byteshexadecimalstring)

Call new() to create a Prowl Public API client object. You must pass the apikey, which you can generate on "settings" page https://prowl.weks.net/settings.php 

  my $apikey = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
  my $ws = WevService::Prowl->new(apikey => $apikey);

=item verify()

Sends a verify request to check if apikey is valid or not. return 1 for success.

  $ws->verify();

=item add(application => $app, event => $event, description => $desc, priority => $pri)

Sends a app request to api and return 1 for success.

  application: [256] (required)
      The name of your application

  event: [1024] (required)
      The name of the event

  description: [10000] (required)
      A description for the event

  priority: An integer value ranging [-2, 2]
      a priority of the notification: Very Low, Moderate, Normal, High, Emergency
      default is 0 (Normal)

  $ws->add(application => "Favotter App",
           event       => "new fav",
           description => "your tweet saved as sekimura's favorite");

=item error()

Returns any error messages as a string.

  $ws->verify() || die $ws->error();

=back

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://prowl.weks.net/>, L<http://forums.cocoaforge.com/viewtopic.php?f=45&t=20339>

=cut
