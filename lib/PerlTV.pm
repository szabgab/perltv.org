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
	_show($data->{videos}[$i]);
};

get '/all' => sub {
	my $data = setting('data');
	template 'list', { videos => $data->{videos} };
};

sub _show {
	my $video = shift;
	$video->{description} = '';
	if ($video->{path}) {
		my $path = Path::Tiny::path(abs_path(config->{appdir}) . "/data/$video->{path}");
		if (-e $path) {
			$video->{description} = $path->slurp_utf8;
		}
	}
	template 'index', { video => $video };
};

get '/:path' => sub {
	my $data = setting('data');
	# would it be better to keep a hash in video.json or to convert it to a hash on load
	my $path = params->{path};
	my ($video) = grep {$_->{path} eq $path } @{ $data->{videos} };
	if ($video) {
		_show($video);
	} else {
		warn "Could not find '$path'";
		return template 'error';
	}
};

true;

