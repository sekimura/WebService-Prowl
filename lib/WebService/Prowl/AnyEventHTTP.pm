package WebService::Prowl::AnyEventHTTP;

use base qw(WebService::Prowl);
use AnyEvent::HTTP;

sub new {
    my $class = shift;
    my %params = @_;
    my $on_error   = delete $params{on_error};
    my $self = $class->SUPER::new(%params);
    $self->{on_error} = $on_error;
    ## $AnyEvent::HTTP::USERAGENT = $self->ua->agent;
    $self;
}

sub add {
    my ( $self, %params ) = @_;
    my $on_error = delete $params{on_error} || $self->{on_error} || sub {};
    my $url = $self->_build_url('add', %params);
    $self->_send_request($url, on_error => $on_error);
}

sub verify {
    my ($self, %params) = @_;
    my $on_error = delete $params{on_error} || $self->{on_error} || sub {};
    my $url = $self->_build_url('verify');
    $self->_send_request($url, on_error => $on_error);
}

sub _send_request {
    my ( $self, $url, %params) = @_;
    my $on_error = delete $params{on_error} || sub {};
    http_get $url,
        sub {
            my ($body, $hdr) = @_;
            my $data = $self->_xmlin($body);
            unless ($hdr->{Status} =~ /^[2]/) {
                $self->{error} =
                    $data->{error}
                  ? $data->{error}{code} . ': ' . $data->{error}{content}
                  : '';
                $on_error->($self, $url, $body, $hdr);
            }
        }
    ;
}

1;
