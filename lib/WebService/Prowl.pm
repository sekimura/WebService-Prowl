package WebService::Prowl;

use strict;
use 5.008_001;
our $VERSION = '0.04';

use LWP::UserAgent;
use URI::Escape qw(uri_escape_utf8);
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
        $params{'providerkey'} ? (providerkey => $params{'providerkey'}) : (),
    }, $class;
}

sub ua { $_[0]->{ua} }

sub error { $_[0]->{error} }

sub _build_url {
    my ( $self, $method, %params ) = @_;
    if ($method eq 'verify') {
        my $url = $API_BASE_URL . 'verify?apikey=' . $self->{apikey};
        $url .= '&providerkey=' . $self->{providerkey} if $self->{providerkey};
        return $url;
    }
    elsif ($method eq 'add') {
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

        my %query = (
            apikey => $self->{apikey},
            $self->{providerkey} ? (providerkey => $self->{providerkey}) : (),
            map { $_  => $req_params->{$_} } @params,
        );
        my @out;
        for my $k (keys %query) {
            push @out, sprintf("%s=%s", uri_escape_utf8($k), uri_escape_utf8($query{$k}));
        }
        my $q = join ('&', @out);
        return $API_BASE_URL . 'add?' . $q;
    }
}

sub add {
    my ( $self, %params, $cb ) = @_;
    my $url = $self->_build_url('add', %params);
    $self->_send_request($url, $cb);
}

sub verify {
    my ($self) = @_;
    my $url = $self->_build_url('verify');
    $self->_send_request($url);
}

sub _send_request {
    my ( $self, $url ) = @_;
    my $res = $self->{ua}->get($url);
    my $data = $self->_xmlin($res->content);
    if ($res->is_error) {
        $self->{error} =
              $data->{error}
            ? $data->{error}{code} . ': ' . $data->{error}{content}
            : '';
        return;
    }
    return 1;
}

sub _xmlin {
    my ( $self, $xml ) = @_;
    if (LIBXML) {
        return XML::LibXML::Simple->new->XMLin( $xml );
    }
    else {
        return XML::Simple->new->XMLin( $xml );
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::Prowl - a interface to Prowl Public API

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

=item new(apikey => 40byteshexadecimalstring, providerkey => yetanother40byteshex)

Call new() to create a Prowl Public API client object. You must pass the apikey, which you can generate on "settings" page https://prowl.weks.net/settings.php 

  my $apikey = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
  my $ws = WevService::Prowl->new(apikey => $apikey);

If you have been whiltelisted, you may want to use 'providerkey' like this:

  my $apikey      = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
  my $providerkey = '68b329da9893e34099c7d8ad5cb9c94010200121';

  my $ws = WevService::Prowl->new(apikey => $apikey, providerkey => $providerkey);

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
