use Test::More tests => 6;
use strict;
use warnings;

# the order is important
use PerlTV;
use Dancer2::Test apps => ['PerlTV'];
use PerlTV::Tools qw(%languages);

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';

for my $language_key (keys %languages) {
	response_status_is ['GET' => '/language/' . $language_key], 200, "response status is 200 for $languages{$language_key}";
}
