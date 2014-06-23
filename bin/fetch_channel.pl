use strict;
use warnings;
use 5.010;
use autodie;

use WWW::Mechanize;
use Data::Dumper qw(Dumper);

my ($url) = @ARGV;
die "Usage: $0 URL (of a YouTube Channel) \n" if not $url;

my %videos;
read_file('imported_videos.txt');
#die Dumper \%videos;

my $m = WWW::Mechanize->new;
$m->get($url);

foreach my $link ($m->links) {
	#say $link->url;
	if ($link->url =~ m{^/watch\?v=([^&]+)}) {
		my $id = $1;
		if (not $videos{$id}) {
			say "https://www.youtube.com/watch?v=$id";
			$videos{$id} = 1;
		}
	}
}
exit;

sub read_file {
	my ($file) = @_;
	open my $fh, '<', $file;
	while (my $row = <$fh>) {
		chomp $row;
		next if $row !~ /^youtube/;
		$videos{ (split /:/, $row)[1] }++;
	}
	close $fh;
}


