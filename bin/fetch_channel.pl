use strict;
use warnings;
use 5.010;
use autodie;

use WWW::Mechanize;
use Data::Dumper qw(Dumper);
use Path::Tiny qw(path);

use lib path($0)->absolute->parent->parent->child('lib')->stringify;
use PerlTV::Import;


my ($url) = @ARGV;
die "Usage: $0 URL (of a YouTube Channel) \n" if not $url;

my $m = WWW::Mechanize->new;
$m->get($url);

my $pi = PerlTV::Import->new;

$pi->import_people();
$pi->import_sources();
my $videos = $pi->import_videos();


foreach my $link ($m->links) {
	#say $link->url;
	if ($link->url =~ m{^/watch\?v=([^&]+)}) {
		my $id = $1;
		if (not $videos->{youtube}{$id}) {
			say "https://www.youtube.com/watch?v=$id";
			$videos->{youtube}{$id} = 1;
		}
	}
}
exit;

sub read_file {
	my ($file) = @_;
	open my $fh, '<', $file;
	while (my $row = <$fh>) {
		chomp $row;
		my ($src, $id) = split /:/, $row;
		$videos->{$src}{$id}++;
	}
	close $fh;
}


