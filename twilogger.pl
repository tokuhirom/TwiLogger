use 5.013002;
use strict;
use warnings;

use AnyEvent::HTTP;
use AE;
use Data::Dumper;
use Try::Tiny;
use Config::Tiny;
use MIME::Base64;
use JSON;
use Getopt::Long;
use Pod::Usage;
use autodie;

my $conffname = 'config.ini';
GetOptions(
    'c|config=s', \$conffname,
    'p|path=s',   \my $path,
);
die "$conffname not found" unless -f $conffname;
pod2usage() unless $path;

my $config = Config::Tiny->read($conffname);
$config = $config->{_};
for (qw/username password/) {
    die "$_ not found in $conffname" unless $config->{$_}
}

my $logger = TwiLogger::Log->new($path);

&main;exit;

sub main {
    http_get "http://chirpstream.twitter.com/2b/user.json",
        headers => {
            Authorization => encode_base64( $config->{username} . ":" . $config->{password} ),
        },
        on_header => sub {
            my ($headers) = @_;
            # print Dumper $headers;
        },
        want_body_handle => 1,    # for some reason on_body => sub {} doesn't work :/
        sub {
            my ( $handle, $headers ) = @_;
            print "parsing\n";
            $handle->push_read( json => \&parse_json );
        };

    AE::cv->recv; # run main loop
}

sub parse_json {
    my ( $handle, $data ) = @_;
    if ( $data->{event} ) {
        $logger->write("event: $data->{event}");
#       try {
#           do_event($data);
#       }
#       catch {
#           error(@_);
#       };
    }
    elsif ( my $del = $data->{delete} ) {
        $logger->write("removed $del->{status}->{id} by $del->{status}->{user_id}");
    }
    elsif ( $data->{text} ) {
        $logger->write(
            sprintf(
                "%s: %s",
                $data->{user}->{screen_name},
                $data->{text},
            )
        );
    }
    else {
        $logger->write( "%s", JSON->new->pretty->encode($data) );
    }
    $handle->push_read( json => \&parse_json );
}

package TwiLogger::Log {
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
        my $header = $now->strftime('%Y-%m-%d %H:%M:%S: ');
        print {$self->{fh}} "$header $body\n";
    }
};

__END__

=head1 SYNOPSIS

    % twilogger.pl -p '/path/to/log/%Y-%m-%d.txt' -c config.ini

    in your config.ini:
    username=foo
    password=passw03d

