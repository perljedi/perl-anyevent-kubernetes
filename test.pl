use lib qw(lib);
use AnyEvent;
use AnyEvent::Kubernetes;
use Data::Dumper;

my $kube = AnyEvent::Kubernetes->new(url => "http://172.18.8.101:8080");

my $cv = AnyEvent->condvar;
$kube->default_namespace->list_pods(cb=>sub { print Dumper(\@_); $cv->send });
$cv->recv;
