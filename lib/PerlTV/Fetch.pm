package PerlTV::Fetch;
use strict;
use warnings;
use 5.010;

use WebService::GData::YouTube ();
use Data::Dumper qw(Dumper);
use Path::Tiny qw(path);
use LWP::Simple qw(get);
use JSON qw(from_json);

use PerlTV::Import;

# http://www.youtube.com/watch?v=QFV7X1tep5I
# https://vimeo.com/77267876

my $txt = '';
my $title = '';

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    my $pi = PerlTV::Import->new;
    $pi->import_people();
    $pi->import_sources();
    $self->{videos} = $pi->import_videos();

    return $self;
}

sub process {
    my ($self, $url, $file) = @_;

    my $u = URI->new($url);
    $self->{uri} = $u;
    if ($u->host eq 'www.youtube.com') {
        $self->youtube;
    } elsif ($u->host eq 'vimeo.com') {
        $self->vimeo;
    
    } else {
    	die "Unknown host " . $u->host;
    }

    if (not $file) {
    	$file = lc $title;
    	$file =~ s/\s+/-/g;
    	$file =~ s/[^a-z0-9-]//g;
    	$file = "data/videos/$file";
    	say $file;
    }
    die "'$file' already exists" if -e $file;
    path($file)->spew_utf8($txt);
}

sub youtube {
    my ($self) = @_;

	my %form = $self->{uri}->query_form;
	my $id = $form{v} or die "Could not find id\n";
	die "This id '$id' has been already included\n" if $self->{videos}{youtube}{$id};
	
	my $yt = WebService::GData::YouTube->new();
	my $video = $yt->get_video_by_id($id);
	$title = $video->title;
	
	$txt .= "id: $id\n";
	$txt .= "src: youtube\n";
	$txt .= "title: $title\n";
	$txt .= "speaker: \n";
	$txt .= "source: \n";
	$txt .= "view_count: " . ($video->view_count||0) . "\n";
	$txt .= "favorite_count: " . ($video->favorite_count||0) . "\n";
	my $length = seconds_to_time($video->duration);   # in seconds
	$txt .= "length: $length\n";
	$txt .= "date: \n";
	$txt .= "format: markdown\n";
	$txt .= "abstract:\n";
	#my $keywords = $video->keywords;
	$txt .= "\n__DESCRIPTION__\n\n";
	$txt .= $video->description . "\n";
}

sub vimeo {
    my ($self) = @_;

	my $id = $self->{uri}->path;
	$id =~ s{^/}{};
	die "vimeo Id is expected to be all digits. This is '$id'\n" if $id !~ /^\d+$/;
	die "This id '$id' has been already included\n" if $self->{videos}{vimeo}{$id};

	#die $id;
	my $url = "http://vimeo.com/api/v2/video/$id.json";
	my $json = get $url;
	#die $json;
	my $list = from_json $json;
	my $data = $list->[0];
	#die Dumper $data;
    $title = $data->{title};

	$txt .= "id: $id\n";
	$txt .= "src: vimeo\n";
	$txt .= "title: $title\n";
    $txt .= "speaker:\n";
	$txt .= "source: \n";
	$txt .= "view_count: $data->{stats_number_of_plays}\n";
	$txt .= "favorite_count: $data->{stats_number_of_likes}\n";
	my $length = seconds_to_time($data->{duration});   # in seconds
	$txt .= "length: $length\n";
	$txt .= "date: \n";
	$txt .= "format: markdown\n";
	$txt .= "abstract:\n";
	$txt .= "thumbnail: $data->{thumbnail_medium}\n";
	$txt .= "tags: $data->{tags}}\n";
	$txt .= "\n__DESCRIPTION__\n\n";
	$txt .= "$data->{description}\n";
}



sub post_print {
    say "Please update the following fields:";
    say "speaker: ";
    say "date: ";
    say "source: ";
    say "modules: ";
    say "tags: ";
}



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


1;

