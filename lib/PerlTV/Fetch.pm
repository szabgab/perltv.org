package PerlTV::Fetch;
use strict;
use warnings;
use 5.010;

# use WebService::GData::YouTube ();
# v2 youtube is dead, use oembed
use Data::Dumper qw(Dumper);
use Path::Tiny qw(path);
use LWP::Simple qw(get);
use JSON qw(from_json);
use Text::CleanFragment;

use PerlTV::Import;

# http://www.youtube.com/watch?v=QFV7X1tep5I
# https://vimeo.com/77267876

sub new {
    my ($class, %defaults) = @_;

    my $self = bless \%defaults, $class;

    my $pi = PerlTV::Import->new;
    $pi->import_people();
    $pi->import_sources();
    $self->{videos} = $pi->import_videos();

    return $self;
}

sub process {
    my ($self, $url, %defaults) = @_;

    $self->{txt}   = '';
    $self->{title} = '';

    $defaults{ source } ||= $self->{source};

    my $u = URI->new($url);
    $self->{uri} = $u;
    if ($u->host eq 'www.youtube.com') {
        # https://www.youtube.com/oembed?url=http://www.youtube.com/watch?v=ojCkgU5XGdg&format=json
        my $u = URI->new('https://www.youtube.com/oembed');
        $self->{uri} = $u;
        $self->youtube( url => $url, %defaults );
    } elsif ($u->host eq 'vimeo.com') {
        $self->vimeo( %defaults );
    
    } else {
    	die "Unknown host " . $u->host;
    }

    my $file = clean_fragment( lc $self->{title} );
    $file = "data/videos/$file";
    say $file;
    die "'$file' already exists" if -e $file;
    path($file)->spew_utf8($self->{txt});
}

sub youtube {
    my ($self, %defaults) = @_;
    $defaults{ source }||= '';

	my %form = URI->new( $defaults{ url })->query_form();
	my $id = $form{v} or die "Could not find id\n";
	die "This id '$id' has been already included\n" if $self->{videos}{youtube}{$id};

    $self->{uri}->query_form({ url => $defaults{ url }, format => 'json' });
    my $res = get( $self->{uri });
    my $video = from_json( $res );
    
	$self->{title} = $video->{title};
	
	my $txt = "id: $id\n";
	$txt .= "src: youtube\n";
    my( $speaker, $title ) = split /\s+-\s+/, $video->{title};
    my $orgspeaker = $speaker;
    ($speaker = lc $speaker) =~ s!\s+!-!g;
    $speaker =~ s!^lightning-talk-by-!!i;
    $speaker =~ s!\.$!!; # for Windows
    
    my $spf = "data/people/$speaker";
    if( ! -f  $spf ) {
        path($spf)->spew_utf8("name: $orgspeaker\n");
    };
    
	$txt .= "title: $title\n";
	$txt .= "speaker: $speaker\n";
	$txt .= "source: $defaults{ source }\n";
	$txt .= "view_count: " . (0) . "\n";
	$txt .= "favorite_count: " . (0) . "\n";
	my $length = seconds_to_time(300);   # in seconds
	$txt .= "length: $length\n";
	$txt .= "date: 2017-06-18\n";
	$txt .= "format: markdown\n";
	$txt .= "abstract:\n";
	#my $keywords = $video->keywords;
	$txt .= "\n__DESCRIPTION__\n\n";
	$txt .=  "<no description>". "\n";
    $self->{txt} .= $txt;

    return;
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
    $self->{title} = $data->{title};

	my $txt = "id: $id\n";
	$txt .= "src: vimeo\n";
	$txt .= "title: $self->{title}\n";
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
    $self->{txt} .= $txt;

    return;
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

