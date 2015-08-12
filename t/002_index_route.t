use Test::More tests => 6;
use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common;
use PerlTV;
use PerlTV::Tools qw(%languages);

system "$^X bin/import_data.pl";

my $app  = PerlTV->to_app;
my $test = Plack::Test->create($app);

my $res = $test->request(GET '/');
ok $res->is_success, 'a route handler is defined for /';
is $res->code, 200, 'response status is 200 for /';

for my $language_key (keys %languages) {
	my $path = '/language/' . $language_key;
	$res = $test->request(GET $path);
	is $res->code, 200, "response status is 200 for $path ($languages{$language_key})";
}
