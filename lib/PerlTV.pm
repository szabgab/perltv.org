package PerlTV;
use Dancer2;

our $VERSION = '0.01';
use Cwd qw(abs_path);
use Path::Tiny ();
use JSON::Tiny ();
use Data::Dumper qw(Dumper);

hook before => sub {
	my $appdir = abs_path config->{appdir};
	my $json = JSON::Tiny->new;
	my $data = $json->decode( Path::Tiny::path("$appdir/videos.json")->slurp_utf8 );
	if (defined $data) {
		set data => $data;
	} else {
		set error => $json->error;
	}
};


get '/' => sub {
	my $error = setting('error');
	if ($error) {
		warn $error;
		return template 'error';
	}

	my $data = setting('data');
	my $i = int rand scalar @{ $data->{videos} };
	my $video = $data->{videos}[$i];
	$video->{description} = '';
	if ($video->{path}) {
		my $path = Path::Tiny::path(abs_path(config->{appdir}) . "/data/$video->{path}");
		if (-e $path) {
			$video->{description} = $path->slurp_utf8;
		}
	}
	template 'index', { video => $video };
};

true;
