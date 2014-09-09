use strict;
use warnings;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;
use Cwd qw(getcwd);
use Carp::Always;


# TODO write some tests for when some of the json files are missing! And provide some reasonable output on the the web site as well.

system "$^X bin/import_data.pl";

use Dancer2;

# avoid unnecessary logging during tests
#set log => 'warning';

#set startup_info => 0;
#Dancer::set( appdir => getcwd() );

#is Dancer2::config->{'appdir'}, getcwd(), 'appdir';

use PerlTV;

my $app = Dancer2->psgi_app;
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
	my $cb = shift;
	like(
		$cb->( GET '/' )->content,
		qr{Other featured videos},
		'main page'
	);
};


