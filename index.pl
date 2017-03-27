#!/usr/bin/perl

use strict;
use CGI;
use DBI;
use Template;

BEGIN {
        require "lib/site_config.pl";
}

my $q = CGI->new;
$q->header(-charset => 'utf-8'),

my $ts    = $q->param("ts"); # /fefe/ timestamp
my $query = $q->param("q");  # /fefe/ search query
my $page  = $q->param("p");  # page for template system

# clean up inputs
$ts =~ s/[^\w]//;
$page =~ s/[^\w]//;


# handle fefe timestamp
if ($ts) {
        my $result;
        my $db_fefe = DBI->connect("dbi:SQLite:dbname=/var/db/fefe/sqlite.db", "", "");
        my $db_board = DBI->connect(SQL_DBI_SOURCE, SQL_USERNAME, SQL_PASSWORD);
        my $sth = $db_fefe->prepare("SELECT thread FROM posts WHERE ts = ?");
        $sth->execute($ts);
        $result = $sth->fetch;
        if ($result) {
                my $r = $result->[0];
                # check existence of the post
                $sth = $db_board->prepare("SELECT num FROM ernstchan_fefe WHERE num = ?");
                $sth->execute($r);
                $result = $sth->fetch;
                $sth->finish;
                if ($result) {
                        print $q->redirect("/fefe/thread/$r");
                } else {
                        print $q->redirect("https://blog.fefe.de/?ts=$ts");
                }
        } else {
                print $q->redirect("https://blog.fefe.de/?ts=$ts");
        }
        $db_fefe->disconnect;
        $db_board->disconnect;
        exit;
}

# redirect to fefe search
if ($query) {
        print $q->redirect("https://blog.fefe.de/?q=$query");
        exit;
}

# no parameter was given, redirect to default board
# redirects should have a full URL: http://ernstchan.com/b/
if (!$page) {
        print $q->redirect(BASE_URL . "/" . DEFAULT_BOARD . "/");
        exit;
}

# handle template page
my $lang = "en";
my @langs = map{ substr($_, 0, 2) } split(",", $ENV{HTTP_ACCEPT_LANGUAGE});
foreach my $l (@langs) { if ($l eq "de") { $lang = "de"; last; } }
my $ttfile = "content/$page.$lang.tt2";

# language strings
my ($err403tit, $err403msg, $err404tit, $err404msg1, $err404msg2);
if ($lang eq "de") {
	$err403tit  = "HTTP-Fehler 403: Zugriff verboten";
	$err403msg  = "Der Zugriff auf diese Ressource ist nicht erlaubt.";
	$err404tit  = "HTTP-Fehler 404: Objekt nicht gefunden";
	$err404msg1 = "Die gew&uuml;nschte Datei existiert nicht oder wurde gel&ouml;scht.";
	$err404msg2 = "Es existiert weder ein Board noch eine Seite mit diesem Namen.";
}
else {
	$err403tit  = "HTTP Error 403: Access forbidden";
	$err403msg  = "Access to this resource is not allowed.";
	$err404tit  = "HTTP Error 404: Object not found";
	$err404msg1 = "The file was deleted or did not exist.";
	$err404msg2 = "No board or page with this name exists.";
}

my $tt = Template->new({
        INCLUDE_PATH => 'tpl/',
        #ENCODING     => 'utf8', # do not set this
        ERROR        => 'error.${lang}.tt2',
        PRE_PROCESS  => 'header.tt2',
        POST_PROCESS => 'footer.tt2',
});

if ($page eq 'err403') {
	tpl_make_error($lang, {
		'http' => '403 Forbidden',
		'image' => "/img/403.png",
		'type' => $err403tit,
		'info' => $err403msg,
	});
}
elsif ($page eq 'err404') {
	tpl_make_error($lang, {
		'http' => '404 Not found',
		'image' => "/img/404.png",
		'type' => $err404tit,
		'info' => $err404msg1,
	});
}
elsif (-f 'tpl/' . $ttfile) {
	my $output;
	if ($tt->process($ttfile, {'tracking_code' => TRACKING_CODE, 'lang' => $lang}, \$output)) {
		print $q->header();
		print $output;
	} else {
		tpl_make_error('en', {
			'http' => '500 Boom',
			'type' => "Server error during script execution",
			'info' => $tt->error
		});
	}
}
else {
	tpl_make_error($lang, {
		'http' => '404 Not found',
		'image' => "/img/404.png",
		'type' => $err404tit,
		'info' => $err404msg2,
	});
}

sub tpl_make_error($$) {
	my ($lang, $params) = @_;
	print $q->header(-status=>$$params{http});
	$tt->process("error.${lang}.tt2", {
		'tracking_code' => TRACKING_CODE,
		'error' => $params,
		'lang'  => $lang,
	});
}
