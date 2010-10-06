use 5.010001;
use strict;
use warnings;

use AnyEvent::Twitter::Stream;
use AE;
use Data::Dumper;
use Try::Tiny;
use Config::Tiny;
use MIME::Base64;
use JSON;
use Getopt::Long;
use Pod::Usage;
use autodie;
use Net::Twitter::Lite;

binmode *STDOUT, ':utf8';

my $conffname = 'config.ini';
GetOptions(
    'c|config=s', \$conffname,
    'p|path=s',   \my $path,
);
die "$conffname not found" unless -f $conffname;
pod2usage() unless $path;

my $config_obj = Config::Tiny->read($conffname);
my $config = $config_obj->{_};
unless ($config->{token}) {
    my $nt = Net::Twitter::Lite->new(
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret}
    );
    my $auth_url = $nt->get_authorization_url();
    print " Authorize this application at: $auth_url\nThen, enter the PIN# provided to continue: ";
    my $pin = <STDIN>; # wait for input
    chomp $pin;
    my @access_tokens = $nt->request_access_token(verifier => $pin);
    $config_obj->{_}->{token} = $access_tokens[0];
    $config_obj->{_}->{token_secret} = $access_tokens[1];
    $config_obj->write($conffname);
    $config = $config_obj->{_};
}
for (qw/username password consumer_key consumer_secret token token_secret/) {
    die "$_ not found in $conffname" unless $config->{$_}
}
{
    my $nt = Net::Twitter::Lite->new(
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
    );
    $nt->access_token($config->{token});
    $nt->access_token_secret($config->{token_secret});
    # say eval { $nt->user_timeline({ count => 1 })->[0]->{text} };
}

my $logger = TwiLogger::Log->new($path);

&main;exit;

sub main {
    my $listener = AnyEvent::Twitter::Stream->new(
        consumer_key    => $config->{consumer_key} // die,
        consumer_secret => $config->{consumer_secret} // die,
        token           => $config->{token} // die,
        token_secret    => $config->{token_secret} // die,
        method          => 'userstream',
        on_connect      => sub {
            say "connected";
        },
        on_error => sub {
            say "error occurred : @_";
        },
        on_tweet => sub {
            my $tweet = shift;
            my $text  = $tweet->{text};
            $text =~ s/\n/ /g;
            $logger->write(
                sprintf( "%s: %s", $tweet->{user}->{screen_name}, $text, ) );
        },
        on_delete => sub {
            my ( $tweet_id, $user_id ) = @_;
            $logger->write("removed ${tweet_id} by ${user_id}");
        },
        timeout => 45,
    );

    AE::cv->recv; # run main loop
}

{
    package TwiLogger::Log;
    use Time::Piece ();
    use IO::Handle;

    sub new {
        my ($class, $path) = @_;
        my $now  = Time::Piece->new;
        my $self = bless {
            path_tmpl => $path,
            date      => $now->ymd,
        }, $class;
        $self->open_fh();
        return $self;
    }

    sub open_fh {
        my ($self) = @_;
        my $now = Time::Piece->new;
        my $path = $now->strftime($self->{path_tmpl});
        open my $fh, '>>:utf8', $path or die "cannot open file: $path: $!";
        $fh->autoflush(1);
        $self->{fh} = $fh;
    }

    sub write {
        my ($self, $body) = @_;
        my $now = Time::Piece->new;
        if ($self->{date} ne $now->ymd) {
            $self->{date} = $now->ymd;
            $self->open_fh();
        }
        my $header = $now->strftime('[%Y-%m-%d %H:%M:%S]');
        print {$self->{fh}} "$header $body\n";
    }
};

__END__

=head1 SYNOPSIS

    % twilogger.pl -p '/path/to/log/%Y-%m-%d.txt' -c config.ini

    in your config.ini:
    username=foo
    password=passw03d

