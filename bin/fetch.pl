use strict;
use warnings;
use 5.010;

use WebService::GData::YouTube ();
use Data::Dumper qw(Dumper);
use Path::Tiny qw(path);

my ($url, $file) = @ARGV;

die "Usage: $0 URL [FILE]\n" if not $url;

# http://www.youtube.com/watch?v=QFV7X1tep5I
my $u = URI->new($url);
my %form = $u->query_form;
my $id = $form{v} or die "Could not find id\n";

my $yt = WebService::GData::YouTube->new();
my $video = $yt->get_video_by_id($id);

my $txt = "id: $id\n";
$txt .= "src: youtube\n";
$txt .= "title: " . $video->title . "\n";
$txt .= "speaker: \n";
#$txt .= "nickname: \n";
#$txt .= "home: \n";
$txt .= "source: \n";
$txt .= "view_count: " . $video->view_count . "\n";
$txt .= "favorite_count: " . $video->favorite_count . "\n";
my $length = seconds_to_time($video->duration);   # in seconds
$txt .= "length: $length\n";
#my $keywords = $video->keywords;
$txt .= "\n__DESCRIPTION__\n\n";
$txt .= $video->description . "\n";

if (not $file) {
	$file = lc $video->title;
	$file =~ s/\s+/-/g;
	$file =~ s/[^a-z-]//g;
	$file = "data/$file";
	say $file;
}
die "'$file' already exists" if -e $file;
path($file)->spew_utf8($txt);

say "Please update the following fields:";
say "speaker: ";
say "nickname: ";
say "home: ";
say "source: ";
say "modules: ";
say "tags: ";



sub seconds_to_time {
    my $dur = shift;
    my $length = sprintf("%0.2d", $dur % 60);
    $dur = int $dur / 60;
	if ($dur) {
		$length = sprintf("%0.2d", $dur % 60) . ":" . $length;
    	$dur = int $dur / 60;
	}
	if ($dur) {
		$length = sprintf("%0.2d", $dur % 60) . ":" . $length;
	}

	return $length;
}



