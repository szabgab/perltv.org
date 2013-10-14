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
	set channels => $json->decode( Path::Tiny::path("$appdir/channels.json")->slurp_utf8 );
	set featured => $json->decode( Path::Tiny::path("$appdir/featured.json")->slurp_utf8 );
	my $data = $json->decode( Path::Tiny::path("$appdir/videos.json")->slurp_utf8 );
	if (defined $data) {
		set data => $data;
	} else {
		set error => $json->error;
	}
};

hook before_template => sub {
	my $t = shift;
	$t->{channels} = setting('channels');
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

	my $appdir = abs_path config->{appdir};
	my $data = read_file( "$appdir/data/$path" );
	$data->{path} = $path;
	template 'index', { video => $data };
};

get '/daily.atom' => sub {
	my $featured = setting('featured');
	my $appdir = abs_path config->{appdir};

	my $URL = request->base;
	$URL =~ s{/$}{};
	my $title = 'PerlTV daily';
	my $ts = $featured->[0]{date};

	my $xml = '';
	$xml .= qq{<?xml version="1.0" encoding="utf-8"?>\n};
	$xml .= qq{<feed xmlns="http://www.w3.org/2005/Atom">\n};
	$xml .= qq{<link href="$URL/daily.atom" rel="self" />\n};
	$xml .= qq{<title>$title</title>\n};
	$xml .= qq{<id>$URL/</id>\n};
	$xml .= qq{<updated>${ts}Z</updated>\n};
	foreach my $entry (@$featured) {

		my $data = read_file( "$appdir/data/$entry->{path}" );

		$xml .= qq{<entry>\n};

		$xml .= qq{  <title>$data->{title}</title>\n};
		$xml .= qq{  <summary type="html"><![CDATA[$data->{description}]]></summary>\n};
		$xml .= qq{  <updated>$entry->{date}Z</updated>\n};
		my $url = "$URL/v/$entry->{path}";
		$xml .= qq{  <link rel="alternate" type="text/html" href="$url" />};
		$xml .= qq{  <id>$entry->{path}</id>\n};
		$xml .= qq{  <content type="html"><![CDATA[$data->{description}]]></content>\n};
		$xml .= qq{</entry>\n};
	}
	$xml .= qq{</feed>\n};

	content_type 'application/atom+xml';
	return $xml;
};


true;

