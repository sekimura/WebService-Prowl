package WebService::Prowl;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use LWP::UserAgent;
use Net::SSLeay;
use Carp qw(croak);

my $API_BASE_URL = 'https://prowl.weks.net/publicapi/';

sub new {
    my $class = shift;
    my %params = @_;
    my $apikey = $params{'apikey'};
    croak("apikey is required") unless $apikey;
    return bless {
        apikey => $params{'apikey'},
        ua => LWP::UserAgent->new(agent => __PACKAGE__ . '/' . $VERSION),
    }, $class;
}

sub add {
    my ($self, %params) = @_;
    my @params = qw/priority application event description/;
    my $req_params = +{ map { $_ => delete $params{$_} } @params };

    croak("event name is required") unless $req_params->{event};
    croak("application name is required") unless $req_params->{application};
    croak("description is required") unless $req_params->{description};
    croak("priority must be in the range [-2, 2]")
        if ($req_params->{priority} < -2 || $req_params->{priority} > 2);

    my $url = $API_BASE_URL . 'add?apikey=' . $self->{apikey} . '&';
    $url .= join('&', map{ $_ . '=' . _ue($req_params->{$_}) } @params );

    $self->{ua}->get($url);
}

sub verify {
    my ($self) = @_;

    my $url = $API_BASE_URL . 'verify?apikey=' . $self->{apikey};
    $self->{ua}->get($url);
}

sub _ue {
    my $str = shift;
    $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $str;
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
    $ws->verify;
    $ws->add(application => "Favotter App",
             event       => "new fav",
             description => "your tweet saved as sekimura's favorite");

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://prowl.weks.net/>, L<http://forums.cocoaforge.com/viewtopic.php?f=45&t=20339>

=cut
