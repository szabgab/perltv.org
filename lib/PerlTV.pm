package PerlTV;
use Dancer2;

our $VERSION = '0.01';
use Cwd qw(abs_path);
use Path::Tiny ();
use JSON::Tiny ();
use Data::Dumper qw(Dumper);

use PerlTV::Tools qw(read_file);

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

hook before_template => sub {
	my $t = shift;
	my $data = setting('data');
	$t->{channels} = $data->{channels};
	return;
};

get '/' => sub {
	my $error = setting('error');
	if ($error) {
		warn $error;
		return template 'error';
	}

	# select a random entry
	my $all = setting('data');
	my $i = int rand scalar @{ $all->{videos} };

	_show($all->{videos}[$i]{path});
};

get '/all' => sub {
	my $data = setting('data');
	template 'list', { videos => $data->{videos} };
};

get '/v/:path' => sub {
	my $path = params->{path};
	if ($path =~ /^[A-Za-z_-]+$/) {
		return _show($path);
	} else {
		warn "Could not find '$path'";
		return template 'error';
	}
};

sub _show {
	my $path = shift;

	my $data = read_file( "data/$path" );
	$data->{path} = $path;
	template 'index', { video => $data };
};


true;

