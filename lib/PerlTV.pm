package PerlTV;
use Dancer2;

our $VERSION = '0.01';
use Cwd qw(abs_path);
use Path::Tiny ();
use JSON::Tiny qw(decode_json);
use Data::Dumper qw(Dumper);
use List::Util qw(min);
use List::MoreUtils qw(uniq);
use Encode;

use PerlTV::Tools qw(read_file youtube_thumbnail get_atom_xml %languages);

hook before => sub {
	my $appdir = abs_path config->{appdir};
	set people => decode_json( Path::Tiny::path("$appdir/people.json")->slurp_utf8 );
	set sources => decode_json( Path::Tiny::path("$appdir/sources.json")->slurp_utf8 );
	set tags => decode_json( Path::Tiny::path("$appdir/tags.json")->slurp_utf8 );
	set modules => decode_json( Path::Tiny::path("$appdir/modules.json")->slurp_utf8 );
	my $featured = decode_json( Path::Tiny::path("$appdir/featured.json")->slurp_utf8 );
	set featured => [ sort {$b->{featured} cmp $a->{featured} }  @$featured ];
	set not_featured => decode_json( Path::Tiny::path("$appdir/not_featured.json")->slurp_utf8 );
	my $data;
	eval {
		$data = decode_json( Path::Tiny::path("$appdir/videos.json")->slurp_utf8 );
	};
	if ($@) {
		set error => 'Could not load videos.json, have you generated it?';
		warn $@;
	} elsif (defined $data) {
		set data => $data;
	}
};

hook before_template => sub {
	my $t = shift;
	$t->{title} //= 'Perl TV';

	my $THUMBNAILS = 4; # shown at the bottom of the front page
	$t->{request} = request;
	my $featured = setting('featured');
	my $end = min($THUMBNAILS, @$featured-1);
	$t->{featured} = [ @{$featured}[1 .. $end] ];

	if ($t->{video} and $t->{video}{start}) {
		my ($min, $sec) = split /:/, $t->{video}{start};
		$t->{video}{start} = $min * 60 + $sec;
	}

	if ($t->{video} and $t->{video}{source}) {
		my $sources = setting('sources');
		$t->{video}{source_name} = $sources->{ $t->{video}{source} }{name};
	}
	if ($t->{video} and $t->{video}{speaker}) {
		my $appdir = abs_path config->{appdir};
		my $person = read_file( "$appdir/data/people/$t->{video}{speaker}" );
		my $people = setting('people');
		$t->{video}{speaker_name} = $person->{name};
		$t->{video}{speaker_home} = $person->{home};
		$t->{video}{speaker_nickname} = $person->{nickname};
		$t->{video}{speaker_twitter} = $person->{twitter};
		$t->{video}{speaker_gplus} = $person->{gplus};
	}
	if ($t->{video} and not $t->{video}{thumbnail}) {
		$t->{video}{thumbnail} = youtube_thumbnail($t->{video}{id});
	}
	if ($t->{videos}) {
		$t->{languages} = {
			map { $_ => $languages{$_} }
			uniq
			map { $_->{language} }
			grep { $_->{language} } @{ $t->{videos} }};
	}

	# on development machine turn these off.
	if (request->base =~ m{http://perltv.org/}) {
		$t->{social} = 1;
		$t->{statistics} = 1;
	}

	if ($t->{videos}) {
		$t->{show_toggles} = 1;
	}

	return;
};

get '/v/dancer-and-dbix' => sub {
	redirect 'http://perltv.org/v/dancer-and-dbix-class';
};
get '/v/how-the-camel-is-de-cocooing' => sub {
	redirect 'http://perltv.org/v/how-the-camel-is-de-cocooning';
};

get '/legal' => sub {
	template 'legal';
};
get '/about' => sub {
	template 'about', {title => "About the Perl TV"};
};

get '/all' => sub {
	my $data = setting('data');
	template 'list', {
		videos => $data->{videos},
		title  => 'All the videos listed in the Perl TV',
	};
};

get '/featured' => sub {
	my $data = setting('data');
	my @videos = grep { $_->{featured} } @{ $data->{videos} };
	template 'list', {
		videos => \@videos,
		title  => 'Featured videos',
	};
};

get qr{/language/([a-z]{2})/featured} => sub {
        my ($language) = splat;
	my $data = setting('data');
	my @videos = grep { $_->{featured} && ($_->{language} eq $language) } @{ $data->{videos} };
	template 'list', {
		videos => \@videos,
		title  => 'Featured videos in ' . $languages{$language},
	};
};


get '/nyf' => sub {
	my $data = setting('data');
	my @videos = grep { ! $_->{featured} } @{ $data->{videos} };
	template 'list', {
		videos => \@videos,
		title  => 'Not yet featured videos',
	};
};


get '/people/?' => sub {
	my $people = setting('people');
	template 'list_people', {
		people => $people,
		title  => 'All the speakers, interviewers and interviewees',
	};
};

get '/people/:name' => sub {
	my $people = setting('people');
	my $name = params->{name};
	pass if not $people->{$name};

	my $appdir = abs_path config->{appdir};
	my $person = read_file( "$appdir/data/people/$name" );
	my $data = setting('data');
	my @entries = grep { $_->{speaker} eq $name} @{ $data->{videos} };
	template 'list', {
		videos => \@entries, %{ $people->{$name} },
		person => $person,
		edit   => "people/$name",
	};
};

get '/tag/?' => sub {
	my $tags = setting('tags');
	template 'list_tags', { tags => $tags };
};

get '/tag/:tag' => sub {
	my $tags = setting('tags');
	my $tag = params->{tag};
	pass if not $tags->{$tag};
	template 'list', { videos => $tags->{$tag}, tag => $tag };
};

get '/module/?' => sub {
	my $modules = setting('modules');
	template 'list_modules', { modules => $modules };
};

get '/module/:name' => sub {
	my $modules = setting('modules');
	my $name = params->{name};
	pass if not $modules->{$name};
	template 'list', { videos => $modules->{$name}, module => $name };
};

get '/source/?' => sub {
	my $sources = setting('sources');
	template 'list_sources', { sources => $sources };
};

get '/source/:name' => sub {
	my $sources = setting('sources');
	my $name = params->{name};
	pass if not $sources->{$name};

	my $data = setting('data');
	my @entries = grep { $_->{source} eq $name} @{ $data->{videos} };
	template 'list', {
		videos => \@entries, %{ $sources->{$name} },
		edit   => "sources/$name",
	};
};

get '/language/?' => sub {
	template 'list_languages', { languages => \%languages };
};

get '/language/:name' => sub {
	my $name = params->{name};
	my $sources = setting('sources');
	my $data = setting('data');
	pass if not $languages{$name};

	my @entries = grep { $_->{language} eq $name} @{ $data->{videos} };
	template 'list', { videos => \@entries, };
};



get '/' => sub {
	# show the currently featured item
	my $featured = setting('featured');
	my @modules = sort {lc $a cmp lc $b} keys %{ setting('modules') };
	my @tags    = sort {lc $a cmp lc $b} keys %{ setting('tags') };
	_show('index', $featured->[0]{path}, {
		title => 'Perl TV, the source for videos, interviews, and screencasts abot the Perl programming language',
		#show_tags    => 1,
		#show_modules => 1,
		#tags         => \@tags,
		#modules      => \@modules,
	});
};

get '/v/:path' => sub {
	my $path = params->{path};
	if ($path =~ /^[A-Za-z0-9_-]+$/) {
		return _show('page', $path, {show_tags => 1, show_modules => 1, edit =>  "videos/$path"});
	} else {
		warn "Could not find '$path'";
		return template 'error';
	}
};

get '/daily.atom' => sub {
	forward '/atom.xml';
};

get '/atom.xml' => sub { # backward functionality for all languages
	my $featured = setting('featured');
	my $URL = request->base;
	$URL =~ s{/$}{};
	my $appdir = abs_path config->{appdir};
	content_type 'application/atom+xml';
        return encode('UTF-8', get_atom_xml(featured => $featured, URL => $URL, appdir => $appdir));
};

get qr{/language/([a-z]{2})/atom.xml} => sub {
        my ($language) = splat;
	my $featured = setting('featured');
	my $URL = request->base;
	$URL =~ s{/$}{};
	my $appdir = abs_path config->{appdir};
	content_type 'application/atom+xml';
        return encode('UTF-8', get_atom_xml(language => $language, featured => $featured, URL => $URL, appdir => $appdir));
};

get '/sitemap.xml' => sub {
	my $data = setting('data');
	my $url = request->base;
	$url =~ s{/$}{};
	content_type 'application/xml';

	my $xml = qq{<?xml version="1.0" encoding="UTF-8"?>\n};
	$xml .= qq{<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n};
	$xml .= qq{  <url>\n};
	$xml .= qq{    <loc>$url/</loc>\n};
	$xml .= qq{  </url>\n};
	foreach my $p (@{ $data->{videos} }) {
		$xml .= qq{  <url>\n};
		$xml .= qq{    <loc>$url/v/$p->{path}</loc>\n};
		#$xml .= qq{    <changefreq>monthly</changefreq>\n};
		#$xml .= qq{    <priority>0.8</priority>\n};
		$xml .= qq{  </url>\n};
	}
	$xml .= qq{</urlset>\n};
	return $xml;
};

sub _show {
	my ($template, $path, $params) = @_;

	$params ||= {};

	my $appdir = abs_path config->{appdir};
	my $data;
	eval {
		$data = read_file( "$appdir/data/videos/$path" );
	};
	if ($@) {
		#warn $@;
		return template 'error';
	}
	my $site_title = $data->{title};
	$data->{path} = $path;
	template $template, {
		video   => $data,
		tags    => $data->{tags},
		modules => $data->{modules},
		title   => $site_title,
		%$params,
	};
};


true;

