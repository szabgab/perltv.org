use strict;
use warnings;
use 5.010;

use Path::Tiny qw(path);

use lib path($0)->absolute->parent->parent->child('lib')->stringify;
use PerlTV::Fetch;

die "Usage: $0 URLs\n" if not @ARGV;
my $fetch = PerlTV::Fetch->new;
foreach my $url (@ARGV) {
	eval {
		$fetch->process($url);
	};
	if ($@) {
		print $@;
	}
}

