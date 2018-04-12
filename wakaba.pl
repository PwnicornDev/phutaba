#!/usr/bin/perl -X

use strict;

use CGI::Carp qw(fatalsToBrowser set_message);

use CGI;
use DBI;
use Net::IP qw(:PROC);
use JSON::XS;
use JSON;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use IO::Socket; # IRC notify
use IO::Select; # wait for DNSBL answer


use constant HANDLER_ERROR_PAGE_HEAD => q{
<!DOCTYPE html>
<html lang="en">
<head>
<title>Phutaba &raquo; Server Error</title>
<meta charset="utf-8" />
<link rel="shortcut icon" href="/img/favicon.ico" />
<link rel="stylesheet" type="text/css" href="/static/css/phutaba.css" />
</head>
<body>
<div class="content">
<header>
	<div class="header">
		<div class="banner"><a href="/"><img src="/banner.pl" alt="Banner" /></a></div>
		<div class="boardname">Server Error</div>
	</div>
</header>
	<hr />

<div class="container" style="background-color: rgba(170, 0, 0, 0.2);margin-top: 50px;"> 
<p>

};

use constant HANDLER_ERROR_PAGE_FOOTER => q{

</p>
</div> 
<p style="text-align: center;margin-top: 50px;"><span style="font-size: small; font-style: italic;">
This is a <strong>fatal error</strong> in the <em>request/response handler</em>. Please contact the administrator of this
site on the <a href="irc://irc.hackint.org/#ernstchan">IRC</a> or via <a href="mailto:admin@ernstchan.com">email</a> and
ask him to fix this error</span></p>

	<hr />
	<footer>Powered by <img src="/img/phutaba_icon.png" alt="" /> <strong>Phutaba</strong>.</footer>
</div>
</body>
</html>
};

# Error Handling
BEGIN {

    sub handler_errors {
        my $msg = shift;
        print HANDLER_ERROR_PAGE_HEAD;
        print $msg;
        print HANDLER_ERROR_PAGE_FOOTER;
    }
    set_message( \&handler_errors );
}

## temporary debug profiling
my ($has_timer, $has_timer_start, $has_timer_output);
BEGIN {
	eval 'use Time::HiRes';
	unless ($@) {
		$has_timer = Time::HiRes::gettimeofday();
		$has_timer_start = $has_timer;
		$has_timer_output = '';
	}
}

#
# Import settings
#

my $query;
use lib 'lib';

BEGIN {
	$query = CGI->new;
	my $board = $query->param("board");
	# todo: this will be replaced by a global list of boards
	$board =~ s/[\*<>|?&]//g; # remove special characters
	$board =~ s/.*[\\\/]//; # remove any leading path

	if (!$board) {
		print "Content-Type: text/plain\n\nMissing board parameter.\n";
		exit;
	}

	if ($board =~ m/[^\wäöü]/) {
		print "Content-Type: text/plain\n\nInvalid board parameter.\n";
		exit;
	}

	if (!-d $board or !-f $board . "/config.pl") {
		print "Content-Type: text/plain\n\nUnknown board.\n";
		exit;
	}
	require $board . "/config.pl";
	require "site_config.pl";
	require "config_defaults.pl";
}
BEGIN {
	require "strings_" . BOARD_LANG . ".pl";
	require "futaba_style.pl";
	require "captcha.pl";
	require "wakautils.pl";
}
debug_exec_time('begin/require');

#
# Optional modules
#

my ($has_encode);

if (CONVERT_CHARSETS) {
    eval 'use Encode qw(decode encode)';
    $has_encode = 1 unless ($@);
}

#
# Global init
#

my $protocol_re = qr/(?:http|https|ftp|mailto|nntp)/;

my $dbh =
  DBI->connect( SQL_DBI_SOURCE, SQL_USERNAME, SQL_PASSWORD,
    { AutoCommit => 1 } )
  or make_error(S_SQLCONF);

my $sth;
$sth = $dbh->prepare("SET NAMES 'latin1';");
$sth->execute() or make_error(S_SQLFAIL);

return 1 if (caller);    # stop here if we're being called externally

#my $query = CGI->new;

my $task  = ( $query->param("task") or $query->param("action"));# unless $query->param("POSTDATA");
#$task = ( $query->url_param("task") ) unless $task;
my $json  = ( $query->param("json") or "" );

	# fill meta-data fields of all existing board files.
	#update_files_meta();
	#update_db_schema2(); # schema migration 2 - change location column
	#update_db_schema3(); # change adminpost column type from tinyint to int - add three new columns to admin table

# check for admin table
init_admin_database() if (!-f BOARD_IDENT . "/sql_created" and !table_exists(SQL_ADMIN_TABLE));

# check for staff table
init_staff_database() if (!-f BOARD_IDENT . "/sql_created" and !table_exists(SQL_STAFF_TABLE));

# check for staff log table
init_staff_log_database() if (!-f BOARD_IDENT . "/sql_created" and !table_exists(SQL_STAFF_LOG_TABLE));


if ($json eq "stats") {
	my $date_format = ($query->param("date_format") or "%Y-%m");
	output_json_stats($date_format);
} elsif ($json) {
	make_error("Unknown json parameter.");
}

if (!-f BOARD_IDENT . "/sql_created" and !table_exists(SQL_TABLE)) { # check for comments table
    init_database();
	init_files_database() unless table_exists(SQL_TABLE_IMG);

    # if nothing exists show the first page.
    show_page(1);
}
elsif ( !$task and !$json ) {
    my $admin  = $query->cookie("wakaadmin");
    # when there is no task, show the first page.
    show_page(1, $admin);
}
elsif ( $task eq "show" ) {
    my $page   = $query->param("page");
    my $thread = $query->param("thread");
    my $post   = $query->param("post");
    my $admin  = $query->cookie("wakaadmin");

    # outputs a single post only
    if (defined($post) and $post =~ /^[+-]?\d+$/)
    {
        show_post($post, $admin);
    }
    # show the requested thread
    elsif (defined($thread) and $thread =~ /^[+-]?\d+$/)
    {
	    if($thread ne 0) {
	        show_thread($thread, $admin);
	    } else {
		    make_error(S_STOP_FOOLING);
	    }
    }
    # show the requested page (if any)
	else
	{
		# fallback to page 1 if parameter was empty or incorrect
		$page = 1 unless (defined($page) and $page =~ /^[+-]?\d+$/);
        show_page($page, $admin);
	}
}
elsif ($task eq "catalog") {
	my $admin = $query->cookie("wakaadmin");
	show_catalog($admin);
}
elsif ($task eq "search") {
	my $find			= $query->param("find");
	my $op_only			= $query->param("op");
	my $in_subject		= $query->param("subject");
	my $in_filenames	= $query->param("files");
	my $in_comment		= $query->param("comment");

	find_posts($find, $op_only, $in_subject, $in_filenames, $in_comment);
}
elsif ( $task eq "post" ) {
    my $parent     = $query->param("parent");
    my $spam1      = $query->param("name");
    my $spam2      = $query->param("link");
    my $name       = $query->param("field1");
    my $email      = $query->param("field2");
    my $subject    = $query->param("field3");
    my $comment    = $query->param("field4");
    my $gb2        = $query->param("gb2");
    my $captcha    = $query->param("captcha");
    my $password   = $query->param("password");
    my $admin      = $query->cookie("wakaadmin");
    my $nofile     = $query->param("nofile");
    my $no_format  = $query->param("no_format");
    my $postfix    = $query->param("postfix");
	my $as_staff   = $query->param("as_staff");
	my @files = $query->multi_param("file"); # multiple uploads, requires CGI.pm v4.08+

    post_stuff(
        $parent,  $spam1,   $spam2,      $name,      $email,
        $subject, $comment, $gb2,        $captcha,   $password,
        $admin,   $nofile,  $no_format,  $postfix,   $as_staff,
        @files
    );
}
elsif ($task eq "fefe") {
	if (defined($ENV{REMOTE_ADDR})) {
		make_error("Aufruf nicht erlaubt.");
	}

	# blog post unix timestamp
	my $ts = ($query->param("ts") or 0);
	$ts = 0 unless ($ts =~ m/[0-9]+/);

	# select a random file from fefe-dir
	my $picdir = ($query->param("picdir") or "img/media/fefe/");
	my ($picture, @files);
	while (glob $picdir . "*") {
		push(@files, $_) if (-f $_);
	}
	$picture = $files[rand @files] if (@files);
	make_error("Could not find a picture in directory $picdir for posting.") if (!$picture);

	open(my $fh, "<", $picture)
		or make_error("Cannot open $picture: $!");
	binmode($fh);

	$ENV{REMOTE_ADDR} = "0.0.0.0"; ##

    my $parent     = "";
    my $spam1      = "";
    my $spam2      = "";
    my $name       = ($query->param("name") or "Herr von Leitner");
    my $email      = "";
    my $subject    = "";
    my $comment    = <STDIN>;
    my $gb2        = "thread";
    my $captcha    = "";
    my $password   = "";
    my $admin      = "xxx"; ## TODO: needs valid session now
    my $nofile     = "";
    my $no_format  = "1";
    my $postfix    = "";
	my $as_staff   = "";

    my $threadid = post_stuff(
		$parent,  $spam1,   $spam2,      $name,      $email,
		$subject, $comment, $gb2,        $captcha,   $password,
		$admin,   $nofile,  $no_format,  $postfix,   $as_staff,
		$fh
    );

	close($fh);

	if ($ts and $threadid) {
		# cannot use make_error() here, because post_stuff() already took care of http output
		$sth = $dbh->prepare("UPDATE "
			. SQL_TABLE
			. " SET timestamp=? WHERE num=? LIMIT 1;");
		$sth->execute($ts, $threadid);
	}
}
elsif ( $task eq "delete" ) {
    my $password = $query->param("password");
    my $fileonly = $query->param("fileonly");
    my $admin    = $query->cookie("wakaadmin");
	my $parent   = $query->param("parent");
    my @posts    = $query->multi_param("delete");

    delete_stuff( $password, $fileonly, $admin, $parent, @posts );
}
elsif ( $task eq "sticky" ) {
    my $admin    = $query->cookie("wakaadmin");
    my $threadid = $query->param("thread");
    make_sticky( $admin, $threadid );
}
elsif ( $task eq "kontra" ) {
    my $admin    = $query->cookie("wakaadmin");
    my $threadid = $query->param("thread");
    make_kontra( $admin, $threadid );
}
elsif ( $task eq "lock" ) {
    my $admin    = $query->cookie("wakaadmin");
    my $threadid = $query->param("thread");
    make_locked( $admin, $threadid );
}
elsif ( $task eq "edit" ) {
    my $admin  = $query->cookie("wakaadmin");
    my $postid = $query->param("post");
    make_admin_edit_panel($admin, $postid);
}
elsif ( $task eq "save" ) {
    my $admin   = $query->cookie("wakaadmin");
    my $postid  = $query->param("post");
    my $name    = $query->param("field1");
    my $subject = $query->param("field3");
    my $comment = $query->param("field4");
    save_admin_edit($admin, $postid, $name, $subject, $comment);
}
elsif ( $task eq "admin" ) {
	my $user        = $query->param("user");
    my $password    = $query->param("berra");        # lol obfuscation
    my $nexttask    = $query->param("nexttask");
    my $savelogin   = $query->param("savelogin");
    my $admincookie = $query->cookie("wakaadmin");

    do_login($user, $password, $nexttask, $savelogin, $admincookie);
}
elsif ( $task eq "logout" ) {
	my $admin = $query->cookie("wakaadmin");
    do_logout($admin);
}
elsif ( $task eq "mpanel" ) {
    my $admin = $query->cookie("wakaadmin");
	make_admin_post_panel($admin);
}
elsif ( $task eq "deleteall" ) {
    my $admin = $query->cookie("wakaadmin");
    my $ip    = $query->param("ip");
    my $mask  = $query->param("mask");
	my $go    = $query->param("go");
    delete_all($admin, parse_range($ip, $mask), $go);
}
elsif ( $task eq "bans" ) {
    my $admin = $query->cookie("wakaadmin");
	my $filter = $query->param("filter");
    make_admin_ban_panel($admin, $filter);
}
elsif ( $task eq "addip" ) {
    my $admin   = $query->cookie("wakaadmin");
    my $type    = $query->param("type");
    my $string  = $query->param("string");
    my $comment = $query->param("comment");
    my $icomment = $query->param("icomment");
    my $ip      = $query->param("ip");
    my $mask    = $query->param("mask");
    my $postid  = $query->param("post");
	my $ajax    = $query->param("ajax");
	my $flag    = $query->param("flag");
	my $global  = $query->param("global");
	my $delete  = $query->param("delete");
    add_admin_entry($admin, $type, $comment, parse_range($ip, $mask),
        $string, $postid, $ajax, $flag, $icomment, $global, $delete);
}
elsif ( $task eq "addstring" ) {
    my $admin   = $query->cookie("wakaadmin");
    my $type    = $query->param("type");
    my $string  = $query->param("string");
    my $comment = $query->param("comment");
    add_admin_entry($admin, $type, $comment, 0, 0, $string, 0, 0, 0, "", 0, 0);
}
elsif ( $task eq "checkban" ) {
    my $ival1	= $query->param("ip");
    my $admin   = $query->cookie("wakaadmin");
    check_admin_entry($admin, $ival1);
}
elsif ( $task eq "removeban" ) {
    my $admin = $query->cookie("wakaadmin");
    my $num   = $query->param("num");
    remove_admin_entry( $admin, $num );
}
elsif ( $task eq "orphans" ) {
    my $admin = $query->cookie("wakaadmin");
    make_admin_orphans($admin);
}
elsif ( $task eq "movefiles" ) {
    my $admin = $query->cookie("wakaadmin");
	my @files = $query->multi_param("file");
	move_files($admin, @files);
}
elsif ( $task eq "log" ) {
    my $admin = $query->cookie("wakaadmin");
	my $filter = $query->param("filter");
	my $show = $query->param("show");
    make_admin_log($admin, $filter, $show);
}
elsif ($task eq "staff") {
	my $admin = $query->cookie("wakaadmin");
	make_admin_users($admin);
}
elsif ($task eq "adduser") {
	my $admin = $query->cookie("wakaadmin");
	my $user = $query->param("user");
	my $password1 = $query->param("password1");
	my $password2 = $query->param("password2");
	my $type = $query->param("type");
	add_user($admin, $user, $password1, $password2, $type);
}
elsif ($task eq "removeuser") {
	my $admin = $query->cookie("wakaadmin");
	my $num = $query->param("num");
	remove_user($admin, $num);
}
elsif ($task eq "enableuser") {
	my $admin = $query->cookie("wakaadmin");
	my $num = $query->param("num");
	change_user($admin, $num, 1);
}
elsif ($task eq "disableuser") {
	my $admin = $query->cookie("wakaadmin");
	my $num = $query->param("num");
	change_user($admin, $num, 0);
}
elsif ($task eq "changepass") {
	my $admin = $query->cookie("wakaadmin");
	my $num = $query->param("num");
	my $oldpw = $query->param("oldpw");
	my $newpw1 = $query->param("newpw1");
	my $newpw2 = $query->param("newpw2");
	change_user_password($admin, $num, $oldpw, $newpw1, $newpw2);
}
else {
	make_error("Unknown task parameter.") unless ($json);
}


$dbh->disconnect();

sub output_json_stats {
	my ($date_format) = @_;
	my (@data, $error, $code, %status, %data, %json);

	$sth = $dbh->prepare(
		"SELECT DATE_FORMAT(FROM_UNIXTIME(`timestamp`), ?) AS `datum`, COUNT(`num`) AS `posts` FROM "
		. SQL_TABLE . " GROUP BY `datum`;");

	$sth->execute(clean_string(decode_string($date_format, CHARSET)));
	$error = $sth->errstr;

	@data = $sth->fetchall_arrayref();
	if(@data ne undef) {
		$code = 200;
		$data{'stats'} = \@data;
	} elsif($sth->rows eq 0) {
		$code = 404;
		$error = 'No data available.';
	} else {
		$code = 500;
	}

	%status = (
		"error_code" => $code,
		"error_msg" => $error,
	);
	%json = (
		"data" => \%data,
		"status" => \%status,
	);

	my $JSON = JSON->new->utf8;
	$JSON = $JSON->pretty(1);
	make_json_header();
	print $JSON->encode(\%json);
}


# sub show_post
# shows a single post out of a thread, essential for the reloadless view of threads
# takes an integer as argument
# returns nothing
sub show_post {
    my ($id, $admin) = @_;
    my ($sth, $row, @thread);

	my ($isAdmin) = check_session($admin, 1);

    $sth = $dbh->prepare(
            "SELECT * FROM "
          . SQL_TABLE
          . " WHERE num=?;" )
      or make_error(S_SQLFAIL);
    $sth->execute( $id ) or make_error(S_SQLFAIL);
	$row = get_decoded_hashref($sth);

    if ($row) {
        add_images_to_row($row);
		$$row{comment} = resolve_reflinks($$row{comment});
        push(@thread, $row);
		my $output =
			encode_string(
				SINGLE_POST_TEMPLATE->(
					thread	     => $id,
					posts        => \@thread,
					single	     => 1,
					admin        => $isAdmin,
					locked       => $thread[0]{locked}
				)
			);
		$output =~ s/^\s+//; # remove whitespace at the beginning
		$output =~ s/^\s+\n//mg; # remove empty lines
		make_http_header();
		print($output);
    }
    else {
		make_http_header();
		print encode_string(
			'<div id="' . $id . '"><div class="post_head post">' . S_NOREC . '</div></div>'
		);
    }
}

sub show_catalog {
    my ($admin) = @_;
    my ($sth, $row, @replycount, @filecount);

	my ($isAdmin) = check_session($admin, 1);

	debug_exec_time('db/init') if ($isAdmin);

    my $total_threads = count_threads();
    my $total_pages = get_page_count($total_threads); # removed $isAdmin

# todos:
# make a <hr> between pages?
# resolve/remove ref-links

	if ($total_threads == 0) {            # no posts on the board
		output_catalog($isAdmin, ());     # make an empty catalog
    }
    else {
		my (@threads);

		# grab all threads for the current page in sticky and bump order
		$sth = $dbh->prepare(
			    "SELECT * FROM "
			  . SQL_TABLE
			  . " WHERE parent=0 ORDER BY sticky DESC,lasthit DESC,num ASC"
			  . " LIMIT ?" # why does 0,? not work?
		) or make_error(S_SQLFAIL);
		$sth->execute(IMAGES_PER_PAGE * $total_pages) or make_error(S_SQLFAIL);

		while ($row = get_decoded_hashref($sth)) {
			$$row{replycount} = 0;
			$$row{filecount} = 0;
			$$row{page} = int(scalar @threads / IMAGES_PER_PAGE) + 1;
			add_images_to_row($row);

			foreach my $file (@{$$row{files}}) {
				$$file{tn_width} = int($$file{tn_width} / 2.5);
				$$file{tn_height} = int($$file{tn_height} / 2.5);
			}

			push @threads, $row;
		}

		# get reply counts for threads
		$sth = $dbh->prepare(
			"SELECT parent,count(*) FROM "
			. SQL_TABLE
			. " WHERE parent>0"
			. " GROUP BY parent;"
		) or make_error(S_SQLFAIL);
		$sth->execute() or make_error(S_SQLFAIL);
		@replycount = @{ $sth->fetchall_arrayref() };
		my %replycount = map { $_->[0] => $_->[1] } @replycount;

		# get file counts for threads
		$sth = $dbh->prepare(
			"SELECT thread,count(*) FROM "
			. SQL_TABLE_IMG
			. " WHERE image IS NOT NULL AND size>0"
			. " GROUP BY thread;"
		) or make_error(S_SQLFAIL);
		$sth->execute() or make_error(S_SQLFAIL);
		@filecount = @{ $sth->fetchall_arrayref() };
		my %filecount = map { $_->[0] => $_->[1] } @filecount;

		foreach my $thread (@threads) {
			$$thread{replycount} = $replycount{$$thread{num}} if ($replycount{$$thread{num}});
			$$thread{filecount} = $filecount{$$thread{num}} if ($filecount{$$thread{num}});
		}

		output_catalog($isAdmin, @threads);
    }
}

sub output_catalog {
	my ($isAdmin, @threads) = @_;
	debug_exec_time('show_catalog') if ($isAdmin);

	my $output =
		encode_string(
            CATALOG_TEMPLATE->(
				threads      => \@threads,
				thread       => 1
            )
		);

	$output =~ s/^\s+\n//mg;

	if ($isAdmin) {
		my $exec_time = debug_exec_time('template', 1);
		$output =~ s!(</body>\n</html>)$!${exec_time}$1!;
	}

	make_http_header();
	print($output);
}

sub show_page {
    my ($pageToShow, $admin) = @_;
    my ($sth, $row, $sth2, $row2, @thread);

	# $isAdmin ($stafftype): 0 = normal user; 1 or 2 = staff
	my ($isAdmin, $staffid, $staffname) = check_session($admin, 1);

	debug_exec_time('db/init') if ($isAdmin);

    my $total_threads = count_threads();
    my $total_pages = get_page_count($total_threads, $isAdmin);

    if ($total_threads == 0) {            # no posts on the board
        output_page(1, 1, $isAdmin, $staffname, ());  # make an empty page 1
    }
    else {
		make_error(S_INVALID_PAGE, 1) if ($pageToShow > $total_pages or $pageToShow <= 0);

		my (@threads, @thread);

		# grab all threads for the current page in sticky and bump order
		$sth = $dbh->prepare(
			    "SELECT * FROM "
			  . SQL_TABLE
			  . " WHERE parent=0 ORDER BY sticky DESC,lasthit DESC,num ASC"
			  . " LIMIT ?,?"
		) or make_error(S_SQLFAIL);
		$sth->execute(IMAGES_PER_PAGE * ($pageToShow - 1), IMAGES_PER_PAGE) or make_error(S_SQLFAIL);

		while ($row = get_decoded_hashref($sth)) {
			@thread = ($row);

			# add posts to thread
			$sth2 = $dbh->prepare(
				    "SELECT * FROM "
				  . SQL_TABLE
				  . " WHERE parent=? ORDER BY num ASC"
			) or make_error(S_SQLFAIL);
			$sth2->execute($$row{num}) or make_error(S_SQLFAIL);

			while ($row2 = get_decoded_hashref($sth2)) {
				push @thread, $row2;
			}

			push @threads, { posts => [@thread] };
		}

		output_page($pageToShow, $total_pages, $isAdmin, $staffname, @threads);
    }
}

sub output_page {
    my ( $page, $total, $isAdmin, $staffname, @threads) = @_;
    my ( $filename, $tmpname, $users );

	$users = get_staff_hashref() if ($isAdmin);

    # do abbrevations and such
    foreach my $thread (@threads) {

		add_images_to_thread(@{$$thread{posts}});

        # split off the parent post, and count the replies and images

        my ( $parent, @replies ) = @{ $$thread{posts} };
        my $replies = @replies;

		# count files in replies - TODO: check for size == 0 for ignoring deleted files
		my $images = 0;
		foreach my $post (@replies) {
			$images += @{$$post{files}} if (exists $$post{files});
		}

        my $curr_replies = $replies;
        my $curr_images  = $images;
        my $max_replies  = REPLIES_PER_THREAD;
        my $max_images   = ( IMAGE_REPLIES_PER_THREAD or $images );

        # in case of a locked thread use custom number of replies
        if ( $$parent{locked} ) {
            $max_replies = REPLIES_PER_LOCKED_THREAD;
            $max_images = ( IMAGE_REPLIES_PER_LOCKED_THREAD or $images );
        }

        # in case of a sticky thread, use custom number of replies
        # NOTE: has priority over locked thread
        if ( $$parent{sticky} ) {
            $max_replies = REPLIES_PER_STICKY_THREAD;
            $max_images = ( IMAGE_REPLIES_PER_STICKY_THREAD or $images );
        }

        # drop replies until we have few enough replies and images
        while ( $curr_replies > $max_replies or $curr_images > $max_images ) {
            my $post = shift @replies;
			# TODO: ignore files with size == 0
			$curr_images -= @{$$post{files}} if (exists $$post{files});
            $curr_replies--;
        }
        # write the shortened list of replies back
        $$thread{posts}      = [ $parent, @replies ];
#        $$thread{omit}       = $replies - $curr_replies;
#        $$thread{omitimages} = $images - $curr_images;
		$$thread{omitmsg}    = get_omit_message($replies - $curr_replies, $images - $curr_images);
		$$thread{num}	     = ${$$thread{posts}}[0]{num};

        # abbreviate the remaining posts
        foreach my $post ( @{ $$thread{posts} } ) {
			# create ref-links
			$$post{comment} = resolve_reflinks($$post{comment});
			$$post{staffname} = $$users{$$post{adminpost}} if ($isAdmin);

            my $abbreviation =
              abbreviate_html( $$post{comment}, MAX_LINES_SHOWN,
                APPROX_LINE_LENGTH );
            if ($abbreviation) {
                $$post{abbrev} = get_abbrev_message(count_lines($$post{comment}) - count_lines($abbreviation));
                $$post{comment_full} = $$post{comment};
                $$post{comment} = $abbreviation;
            }
        }
    }

    # make the list of pages
    my @pages = map +{ page => $_ }, ( 1 .. $total );
    foreach my $p (@pages) {
        #if ( $$p{page} == 1 ) {
		#		$$p{filename} = expand_filename("wakaba.pl");			
        #}    # first page
        #else {
			#$$p{filename} = expand_filename( "wakaba.pl?task=show&amp;page=" . $$p{page} );
			$$p{filename} = expand_filename( "page/" . $$p{page} );
        #}
        if ( $$p{page} == $page ) { $$p{current} = 1 }   # current page, no link
    }

    my ( $prevpage, $nextpage );
	# phutaba pages:    1 2 3
	# perl array index: 0 1 2
	# example for page 2: the prev page is at array pos 0, current page at array pos 1, next page at array pos 2
    $prevpage = $pages[ $page - 2 ]{filename} if ( $page != 1 );
    $nextpage = $pages[ $page     ]{filename} if ( $page != $total );

	my $loc = get_geolocation(get_remote_addr());

	debug_exec_time('show_page') if ($isAdmin);

	my $output =
		encode_string(
            PAGE_TEMPLATE->(
				postform     => (ALLOW_TEXTONLY or ALLOW_IMAGES or $isAdmin),
				image_inp    => (ALLOW_IMAGES or $isAdmin),
				textonly_inp => (ALLOW_IMAGES and ALLOW_TEXTONLY),
				captcha_inp  => (!$isAdmin and need_captcha(CAPTCHA_MODE, CAPTCHA_SKIP, $loc)),
				prevpage     => $prevpage,
				nextpage     => $nextpage,
				pages        => \@pages,
				loc          => $loc,
				threads      => \@threads,
				staffname    => $staffname,
				admin        => $isAdmin
            )
		);

	$output =~ s/^\s+\n//mg;

	if ($isAdmin) {
		my $exec_time = debug_exec_time('template', 1);
		$output =~ s!(</body>\n</html>)$!${exec_time}$1!;
	}

	make_http_header();
	print($output);
}

sub get_omit_message($$) {
	my ($posts, $files) = @_;
	return "" if !$posts;

	my $omitposts = S_ABBR1;
	$omitposts = sprintf(S_ABBR2, $posts) if ($posts > 1);

	my $omitfiles = "";
	$omitfiles = S_ABBRIMG1 if ($files == 1);
	$omitfiles = sprintf(S_ABBRIMG2, $files) if ($files > 1);

	return $omitposts . $omitfiles . S_ABBR_END;
}

sub get_abbrev_message($) {
	my ($lines) = @_;
	return S_ABBRTEXT1 if ($lines <= 1); # oh well
	return sprintf(S_ABBRTEXT2, $lines);
}

sub show_thread {
    my ($thread, $admin) = @_;
    my ( $sth, $row, @thread, $users );
#    my ( $filename, $tmpname );

	# $isAdmin ($stafftype): 0 = normal user; 1 or 2 = staff
	my ($isAdmin, $staffid, $staffname) = check_session($admin, 1);

	debug_exec_time('db/init') if ($isAdmin);

	$users = get_staff_hashref() if ($isAdmin);

	## get the actual thread
    $sth = $dbh->prepare(
            "SELECT * FROM "
          . SQL_TABLE
          . " WHERE num=? OR parent=? ORDER BY num ASC;"
    ) or make_error(S_SQLFAIL);
    $sth->execute( $thread, $thread ) or make_error(S_SQLFAIL);

	while ( $row = get_decoded_hashref($sth) ) {
		$$row{comment} = resolve_reflinks($$row{comment});
		$$row{staffname} = $$users{$$row{adminpost}} if ($isAdmin);
		push( @thread, $row );
	}
	make_error(S_NOTHREADERR, 1) if ( !$thread[0] or $thread[0]{parent} );

	## determine if the thread is visible or not
	my $visible = 0;
	my $total_pages = get_page_count(MAX_THREADS, $isAdmin);

	$sth = $dbh->prepare(
			"SELECT num FROM "
		  . SQL_TABLE
		  . " WHERE parent=0 ORDER BY sticky DESC,lasthit DESC,num ASC"
		  . " LIMIT ?"
	) or make_error(S_SQLFAIL);
	$sth->execute(IMAGES_PER_PAGE * $total_pages) or make_error(S_SQLFAIL);

	while ($row = $sth->fetchrow_arrayref()) {
		if ($$row[0] == $thread) {
			$visible = 1;
			last;
		}
	}
	# the thread exists but is not on a visible page anymore
    make_error(S_NOTHREADERR, 1) if (!$visible);

	add_images_to_thread(@thread);

	my $loc = get_geolocation(get_remote_addr());
	my $locked = $thread[0]{locked};

	debug_exec_time('show_thread') if ($isAdmin);

	my $output =
        encode_string(
            PAGE_TEMPLATE->(
				thread       => $thread,
				locked       => $locked,
				title        => $thread[0]{subject},
				postform     => ((ALLOW_TEXT_REPLIES or ALLOW_IMAGE_REPLIES) and !$locked or $isAdmin),
				image_inp    => (ALLOW_IMAGE_REPLIES or $isAdmin),
				textonly_inp => 0,
				captcha_inp  => (!$isAdmin and need_captcha(CAPTCHA_MODE, CAPTCHA_SKIP, $loc)),
				dummy        => $thread[$#thread]{num},
				loc          => $loc,
				threads      => [ { posts => \@thread } ],
				staffname    => $staffname,
				admin        => $isAdmin
            )
        );
	$output =~ s/^\s+\n//mg;

	if ($isAdmin) {
		my $exec_time = debug_exec_time('template', 1);
		$output =~ s!(</body>\n</html>)$!${exec_time}$1!;
	}

	make_http_header();
	print($output);
}

sub get_files($$$) {
	my ($threadid, $postid, $files) = @_;
	my ($sth, $res, $where, $uploadname);

	if ($threadid) {
		# get all files of a thread with one query
		$where = " WHERE thread=? OR post=? ORDER BY post ASC, num ASC;";
	} else {
		# get all files of one post only
		$where = " WHERE post=? ORDER BY num ASC;";
	}

	$sth = $dbh->prepare(
		  "SELECT * FROM "
		. SQL_TABLE_IMG .
		  $where
	) or make_error(S_SQLFAIL);

	if ($threadid) {
		$sth->execute($threadid, $threadid) or make_error(S_SQLFAIL);
	} else {
		$sth->execute($postid) or make_error(S_SQLFAIL);
	}

	while ($res = get_decoded_hashref($sth)) {
		$uploadname = remove_path($$res{uploadname});
		$$res{uploadname} = clean_string($uploadname);
		$$res{displayname} = clean_string(get_displayname($uploadname));

		# static thumbs are not used anymore (for old posts)
		$$res{thumbnail} = undef if ($$res{thumbnail} =~ m|^\.\./img/|);

		# true if STUPID_THUMBNAILING is/was enabeld, do not change any paths
		unless ($$res{image} eq $$res{thumbnail}) {
			# remove any leading path that was stored in the database (for old posts)
			$$res{image} =~ s!.*/!!;
			$$res{thumbnail} =~ s!.*/!!;

			$$res{image} = IMG_DIR . $$res{image};  # add directory to filenames
			$$res{thumbnail} = THUMB_DIR . $$res{thumbnail} if ($$res{thumbnail});
		}

		push(@{$files}, $res);
	}
}

sub add_images_to_thread(@) {
	my (@posts) = @_;
	my ($sthfiles, $res, @files, $uploadname, $post);

	@files = ();
	get_files($posts[0]{num}, 0, \@files);
	return unless (@files);

	foreach $post (@posts) {
		while (@files and $$post{num} == $files[0]{post}) {
			push(@{$$post{files}}, shift(@files))
		}
	}
}

sub add_images_to_row($) {
    my ($row) = @_;
	my @files = (); # all files of one post for loop-processing in the template

	get_files(0, $$row{num}, \@files);
	$$row{files} = [@files] if (@files); # copy the array to an arrayref in the post
}

sub resolve_reflinks($) {
	my ($comment) = @_;

	$comment =~ s|<!--reflink-->&gt;&gt;([0-9]+)|
		my $res = get_post($1);
		if ($res) { '<span class="backreflink"><a href="'
			. get_reply_link($$res{num},$$res{parent}) . '">&gt;&gt;'.$1.'</a></span>' }
		else { '<span class="backreflink"><del>&gt;&gt;'.$1.'</del></span>'; }
	|ge;

	$comment =~ s|<!--reflink-->&gt;&gt;/([\wäöü]+)/([0-9]+)|
		my $res = get_board_post($1,$2);
		if ($res) { '<span class="boardreflink"><a href="'
			. get_reply_link($$res{num},$$res{parent},$1) . '">&gt;&gt;/'.$1.'/'.$2.'</a></span>' }
		else { '<span class="backreflink"><del>&gt;&gt;/'.$1.'/'.$2.'</del></span>'; }
	|e for 1 .. 10;

	return $comment;
}

sub print_page {
    my ( $filename, $contents ) = @_;

    $contents = encode_string($contents);

    #		$PerlIO::encoding::fallback=0x0200 if($has_encode);
    #		binmode PAGE,':encoding('.CHARSET.')' if($has_encode);

    if (USE_TEMPFILES) {
        my $tmpname = RES_DIR . 'tmp' . int( rand(1000000000) );

        open( PAGE, ">$tmpname" ) or make_error(S_NOTWRITE);
        print PAGE $contents;
        close PAGE;

        rename $tmpname, $filename;
    }
    else {
        open( PAGE, ">$filename" ) or make_error(S_NOTWRITE);
        print PAGE $contents;
        close PAGE;
    }
}

sub dnsbl_check {
    my ($ip) = @_;

	return if ($ip =~ /:/); # IPv6

	eval 'use Net::DNS';
	return if ($@);

    foreach my $dnsbl_info ( @{&DNSBL_INFOS} ) {
        my $dnsbl_host   = @$dnsbl_info[0];
        my $dnsbl_answer = @$dnsbl_info[1];
        my $dnsbl_error  = @$dnsbl_info[2];
        my $result;
        my $resolver;
        my $reverse_ip    = join( '.', reverse split /\./, $ip );
        my $dnsbl_request = join( '.', $reverse_ip,        $dnsbl_host );

        $resolver = Net::DNS::Resolver->new;
        my $bgsock = $resolver->bgsend($dnsbl_request);
        my $sel    = IO::Select->new($bgsock);

        my @ready = $sel->can_read(DNSBL_TIMEOUT);
        if (@ready) {
            foreach my $sock (@ready) {
                if ( $sock == $bgsock ) {
                    my $packet = $resolver->bgread($bgsock);
                    if ($packet) {
                        foreach my $rr ( $packet->answer ) {
                            next unless $rr->type eq "A";
                            $result = $rr->address;
                            last;
                        }
                    }
                    $bgsock = undef;
                }
                $sel->remove($sock);
                $sock = undef;
            }
        }

		make_ban(S_BADHOSTPROXY, {ip => $ip, showmask => 0, reason => $dnsbl_error})
			if ($result eq $dnsbl_answer);
    }
}


sub find_posts($$$$) {
	my ($find, $op_only, $in_subject, $in_filenames, $in_comment) = @_;
	# TODO: add $admin / admin-reflinks?

	#todo: search in filenames
	#todo: remove hide thread button, remove checkboxes in front of postername

	$find = clean_string(decode_string($find, CHARSET));
	$find =~ s/^\s+|\s+$//g; # trim
	$in_comment = 1 unless $find; # make the box checked for the first call.	

	my ($sth, $row);
	my ($search, $subject);
	my $lfind = lc($find); # ignore case
	my $count = 0;
	my $threads = 0;
	my @results = ();

	if (length($lfind) >= 3) {
		# grab all posts, in thread order (ugh, ugly kludge)
		$sth = $dbh->prepare(
			"SELECT * FROM " . SQL_TABLE
			  . " ORDER BY sticky DESC,lasthit DESC,CASE parent WHEN 0 THEN num ELSE parent END ASC,num ASC"
		) or make_error(S_SQLFAIL);
		$sth->execute() or make_error(S_SQLFAIL);

		while (($row = get_decoded_hashref($sth)) and ($count < MAX_SEARCH_RESULTS)
		  and ($threads <= MAX_SHOWN_THREADS)) {
			$threads++ if !$$row{parent};
			$search = $$row{comment};
			$search =~ s/<.+?>//mg; # must not search inside html-tags. remove them.
			$search = lc($search);
			$subject = lc($$row{subject});

			if (($in_comment and (index($search, $lfind) > -1)) or
			  ($in_subject and (index($subject, $lfind) > -1))) {

# highlight found words - this can break HTML tags
# TODO: select or define CSS style
#$$row{comment} =~ s/($find)/<span style="background-color: #706B5E; color: #FFFFFF; font-weight: bold;">$1<\/span>/ig;

				add_images_to_row($row);
				$$row{comment} = resolve_reflinks($$row{comment});
				if (!$$row{parent}) { # OP post
					push @results, $row;
				} else { # reply post
					push @results, $row unless ($op_only);
				}
				$count = @results;
			}
		}
		$sth->finish(); # Clean up the record set
	}

	my $output =
		encode_string(
			SEARCH_TEMPLATE->(
				title		=> S_SEARCHTITLE,
				posts		=> \@results,
				find		=> $find,
				oponly		=> $op_only,
				insubject	=> $in_subject,
				filenames	=> $in_filenames,
				comment		=> $in_comment,
				count		=> $count,
				admin		=> 0
			)
		);

	$output =~ s/^\s+\n//mg;
	make_http_header();
	print($output);
}


#
# Posting
#
sub post_stuff {
    my (
        $parent,  $spam1,   $spam2,     $name,    $email,
        $subject, $comment, $gb2,       $captcha, $password,
        $admin,   $nofile,  $no_format, $postfix, $as_staff,
        @files
    ) = @_;

	my $file = $files[0];
	#my $uploadname = $files[0];

    my $original_comment = $comment;
    # get a timestamp for future use
    my $time = time();

    # check that the request came in as a POST, or from the command line
    make_error(S_UNJUST)
      if ( $ENV{REQUEST_METHOD} and $ENV{REQUEST_METHOD} ne "POST" );

    my ($stafftype, $staffid) = check_session($admin, 1);

	# clean up invalid admin cookie/session or posting would fail
	$admin = "" unless ($stafftype);

    if ($admin)  # check admin session
    {
        check_session($admin);
    }
    else {

        # forbid admin-only features
        make_error(S_WRONGPASS) if ( $no_format or $postfix or $as_staff );

        # check what kind of posting is allowed
        if ($parent) {
            make_error(S_NOTALLOWED4) if ($file  and !ALLOW_IMAGE_REPLIES);
            make_error(S_NOTALLOWED3) if (!$file and !ALLOW_TEXT_REPLIES);
        }
        else {
            make_error(S_NOTALLOWED2) if ($file  and !ALLOW_IMAGES);
            make_error(S_NOTALLOWED1) if (!$file and !ALLOW_TEXTONLY);
        }
    }

    # check for weird characters
    make_error(S_UNUSUAL) if ( $parent  =~ /[^0-9]/ );
    make_error(S_UNUSUAL) if ( length($parent) > 10 );
    make_error(S_UNUSUAL) if ( $name    =~ /[\n\r]/ );
    make_error(S_UNUSUAL) if ( $email   =~ /[\n\r]/ );
    make_error(S_UNUSUAL) if ( $subject =~ /[\n\r]/ );

    # check for excessive amounts of text
    make_error(S_TOOLONG1) if ( length($name) > MAX_FIELD_LENGTH );
    make_error(S_TOOLONG1) if ( length($email) > MAX_FIELD_LENGTH );
    make_error(S_TOOLONG1) if ( length($subject) > MAX_FIELD_LENGTH );
    make_error(S_TOOLONG2) if ( length($comment) > MAX_COMMENT_LENGTH and !$admin ); # fefe hack

    # check to make sure the user selected a file, or clicked the checkbox
    make_error(S_NOPIC) if ( !$parent and !$file and !$nofile and !$admin );

    # check for empty reply or empty text-only post
    make_error(S_NOTEXT) if ( $comment =~ /^\s*$/ and !$file );

    # get file size, and check for limitations.
	my @size;
	for (my $i = 0; $i < MAX_FILES; $i++) {
		$size[$i] = get_file_size($files[$i]) if ($files[$i]);
	}

    # find IP
    #my $ip  = $ENV{REMOTE_ADDR};
    #my $ip  = substr($ENV{HTTP_X_FORWARDED_FOR}, 6); # :ffff:1.2.3.4
	my $ip = get_remote_addr();	
    my $ssl = $ENV{HTTP_X_ALUHUT};
	$ssl =  $ENV{SSL_CIPHER} unless $ssl;
    undef($ssl) unless $ssl;

    #$host = gethostbyaddr($ip);
	my $numip = dot_to_dec($ip);

    # set up cookies
    my $c_name     = $name;
    my $c_email    = $email;
    my $c_password = $password;
    my $c_gb2      = $gb2;

    # check if IP is whitelisted
    my $whitelisted = is_whitelisted($numip);
    dnsbl_check($ip) if ( !$whitelisted and ENABLE_DNSBL_CHECK );

    # process the tripcode - maybe the string should be decoded later
    my $trip;
    ( $name, $trip ) = process_tripcode( $name, TRIPKEY, SECRET, CHARSET );

	# get as number and owner
	my ($as_num, $as_info) = get_as_info($ip);
	$as_info = clean_string($as_info);

    # check for bans
    ban_check($numip, $c_name, $subject, $comment, $as_num) unless $whitelisted;

	# check for spam trap fields
	if ($spam1 or $spam2) {
		my ($banip, $banmask) = parse_range($numip, '');

		$sth = $dbh->prepare(
			"INSERT INTO " . SQL_ADMIN_TABLE . " VALUES(null,?,?,?,?,?,FROM_UNIXTIME(?));")
		  or make_error(S_SQLFAIL);
		$sth->execute('ipban', S_AUTOBAN, $banip, $banmask, $time + 259200, $time)
		  or make_error(S_SQLFAIL);

		make_error(S_SPAM);
	}

	# get geoip info
	my ($city, $region_name, $country_name, $loc) = get_geolocation($ip);
	$region_name = "" if ($region_name eq $city);
	$region_name = clean_string($region_name);
	$city = clean_string($city);
    # check captcha
    check_captcha( $dbh, $captcha, $ip, $parent, BOARD_IDENT )
      if (need_captcha(CAPTCHA_MODE, CAPTCHA_SKIP, $loc) and !$admin and !is_trusted($trip));
	$loc = join("<br />", $loc, $country_name, $region_name, $city, $as_info);

    # check if thread exists, and get lasthit value
    my ($parent_res, $lasthit, $autosage, $sticky);
    if ($parent) {
        $parent_res = get_parent_post($parent) or make_error(S_NOTHREADERR);
        $lasthit = $$parent_res{lasthit};
        $autosage = $$parent_res{autosage};
        $sticky = $$parent_res{sticky};
		make_error(S_LOCKED) if ($$parent_res{locked} and !$admin);
    }
    else {
        $lasthit = $time;
		undef($autosage);
		undef($sticky),
    }

    # kill the name if anonymous posting is being enforced
    if (FORCED_ANON && !$admin) {
        $name = '';
        $trip = '';
		if(ENABLE_RANDOM_NAMES) {
			my @names = RANDOM_NAMES;
			$name = $names[rand(@names)];
		}
        if   ($email) { $email = 'sage'; }
        else          { $email = ''; }
    }

    # clean up the inputs
    $email   = clean_string( decode_string( $email,   CHARSET ) );
    $subject = clean_string( decode_string( $subject, CHARSET ) );

    # fix up the email/link
    $email = "mailto:$email" if $email and $email !~ /^$protocol_re:/;

    # format comment
    $comment =
      format_comment( clean_string( decode_string( $comment, CHARSET ) ) )
      unless $no_format;
    $comment .= $postfix;

    # insert default values for empty fields
    $parent = 0 unless $parent;
    $name    = make_anonymous( $ip, $time ) unless $name or $trip;
    $subject = S_ANOTITLE                   unless $subject;
    $comment = S_ANOTEXT                    unless $comment;
    $original_comment = "empty"		    unless $original_comment;
#    $original_comment =~ s/\n/ /gm;

    # flood protection - must happen after inputs have been cleaned up
    flood_check( $numip, $time, $comment, $file, $parent ) unless $admin; # fefe hack

    # Manager and deletion stuff - duuuuuh?

    # copy file, do checksums, make thumbnail, etc
    my (@filename, @md5, @width, @height, @thumbnail, @tn_width, @tn_height, @info, @info_all, @uploadname);

	for (my $i = 0; $i < MAX_FILES; $i++) {
		if ($files[$i]) {
			# TODO: replace by $time when open_unique works
			my $file_ts = time() . sprintf("-%03d", int(rand(1000)));
			$file_ts = $time unless ($i);

			($filename[$i], $md5[$i], $width[$i], $height[$i],
				$thumbnail[$i], $tn_width[$i], $tn_height[$i],
				$info[$i], $info_all[$i], $uploadname[$i])
				= process_file($files[$i], $files[$i], $file_ts);

			# disabled because it breaks STUPID_THUMBNAILING => 1
			#$filename[$i] =~ s!.*/!!; # remove leading path before writing to database
			#$thumbnail[0] =~ s!.*/!!;
		}
	}

    $numip = "0" if (ANONYMIZE_IP_ADDRESSES);

	if ($as_staff) { $as_staff = $staffid; }
	else           { $as_staff = 0; };

    # finally, write to the database
    my $sth = $dbh->prepare(
        "INSERT INTO " . SQL_TABLE . "
		VALUES(null,?,?,?,?,?,?,?,?,?,?,null,null,?,null,?,?,?);"
    ) or make_error(S_SQLFAIL);
    $sth->execute(
		$parent,    $time,     $lasthit,   $numip,
		$name,      $trip,     $email,     $subject,
		$password,  $comment,  $as_staff,  $sticky,
		$loc,       $ssl
    ) or make_error(S_SQLFAIL);

	# get the new post id
	$sth = $dbh->prepare("SELECT " . get_sql_lastinsertid() . ";") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	my $new_post_id = ($sth->fetchrow_array())[0];

	# insert file information into database
	if ($file) {
		$sth = $dbh->prepare("INSERT INTO " . SQL_TABLE_IMG . " VALUES(null,?,?,?,?,?,?,?,?,?,?,?,?,?);" )
			or make_error(S_SQLFAIL);

		my $thread_id = $parent;
		$thread_id = $new_post_id if (!$parent);

		for (my $i = 0; $i < MAX_FILES; $i++) {
			($sth->execute(
				$thread_id, $new_post_id, $filename[$i], $size[$i], $md5[$i], $width[$i], $height[$i],
				$thumbnail[$i], $tn_width[$i], $tn_height[$i], $uploadname[$i], $info[$i], $info_all[$i]
			) or make_error(S_SQLFAIL)) if ($files[$i]);
		}
	}

    if (ENABLE_IRC_NOTIFY) {
		my $socket = new IO::Socket::INET(
			PeerAddr => IRC_NOTIFY_HOST,
			PeerPort => IRC_NOTIFY_PORT,
			Proto    => "tcp"
		);
		if ($socket) {
			if ( $parent and IRC_NOTIFY_ON_NEW_POST ) {
				print $socket S_IRC_NEW_POST_PREPEND . "/"
				  . encode_string(BOARD_IDENT) . "/: "
				  . S_IRC_BASE_BOARDURL
				  . encode_string(BOARD_IDENT)
				  . S_IRC_BASE_THREADURL
				  . $parent . "#"
				  . $new_post_id . " ["
				  . get_preview($original_comment) . "]\n";
			}
			elsif ( !$parent and IRC_NOTIFY_ON_NEW_THREAD ) {
				print $socket S_IRC_NEW_THREAD_PREPEND . "/"
				  . encode_string(BOARD_IDENT) . "/: "
				  . S_IRC_BASE_BOARDURL
				  . encode_string(BOARD_IDENT)
				  . S_IRC_BASE_THREADURL
				  . $new_post_id . " ["
				  . get_preview($original_comment) . "]\n";
			}
			close($socket);
		}
    }

    if (ENABLE_WEBSOCKET_NOTIFY) {
        my $ufoporno = system('/usr/local/bin/push-post', BOARD_IDENT, $parent, $new_post_id, "2>&1", ">/dev/null");
    }

    if ($parent and !$autosage)    # bumping
    {
		my $bumplimit = (MAX_RES and sage_count($parent_res) > MAX_RES);

        # check for sage, or too many replies
        unless ($email =~ /sage/i or $bumplimit) {
            $sth =
              $dbh->prepare( "UPDATE "
                  . SQL_TABLE
                  . " SET lasthit=? WHERE num=? OR parent=?;" )
                  or make_error(S_SQLFAIL);
            $sth->execute($time, $parent, $parent) or make_error(S_SQLFAIL);
        }

		# bumplimit reached, set flag in thread OP
        if ($bumplimit) {
            $sth =
              $dbh->prepare( "UPDATE "
                  . SQL_TABLE
                  . " SET autosage=1 WHERE num=?;" )
                  or make_error(S_SQLFAIL);
            $sth->execute($parent) or make_error(S_SQLFAIL);
        }
    }

    # remove old threads from the database
    trim_database();

	# log entry on staff post
	add_log_entry("Staff post", $staffid, $new_post_id) if ($as_staff);

    # set the name, email and password cookies
    make_cookies(
        name      => $c_name,
        #email     => $c_email,
        gb2       => $c_gb2,
        password  => $c_password,
        -charset  => CHARSET,
        -autopath => COOKIE_PATH,
        -expires  => time + 14 * 24 * 3600
    );    # yum!

	# go back to thread or board page
	if ($c_gb2 =~ /thread/i) {
		make_http_forward(get_board_id() . "/thread/" . $parent . "#" . $new_post_id) if ($parent);
		make_http_forward(get_board_id() . "/thread/" . $new_post_id) if (!$parent);
	}
	else {
		make_http_forward(get_board_id() . "/");
	}

	return $new_post_id; # fefe hack
}

sub is_whitelisted {
    my ($numip) = @_;
    my ($sth, $where);

	if (length(pack('w', $numip)) > 5) { # IPv6 - no support for network masks yet, only single hosts
		$where = " WHERE type='whitelist' AND ival1=?;";
	} else { # IPv4
		$where = " WHERE type='whitelist' AND ? & ival2 = ival1 & ival2;";
	}
    $sth =
      $dbh->prepare( "SELECT count(*) FROM "
          . SQL_ADMIN_TABLE
          . $where)
      or make_error(S_SQLFAIL);
    $sth->execute($numip) or make_error(S_SQLFAIL);

    return 1 if ( ( $sth->fetchrow_array() )[0] );

    return 0;
}

sub is_trusted {
    my ($trip) = @_;
    my ($sth);
    $sth =
      $dbh->prepare( "SELECT count(*) FROM "
          . SQL_ADMIN_TABLE
          . " WHERE type='trust' AND sval1 = ?;" )
      or make_error(S_SQLFAIL);
    $sth->execute($trip) or make_error(S_SQLFAIL);

    return 1 if ( ( $sth->fetchrow_array() )[0] );

    return 0;
}

sub apply_wordfilter {
	my ($comment) = @_;
	my ($sth, $row, @words);
    $sth =
      $dbh->prepare( "SELECT sval1,comment FROM "
          . SQL_ADMIN_TABLE
          . " WHERE type='filter';" )
      or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

	while ($row = get_decoded_hashref($sth)) {
		@words = split('\|', $$row{comment});
		$comment =~ s/$$row{sval1}/$words[rand @words]/ig;
	}

	return $comment;
}

sub ban_check {
    my ($numip, $name, $subject, $comment, $as_num) = @_;
    my ($sth, $row);
    my $ip  = dec_to_dot($numip);

	# check for as num ban
	if ($as_num) {
		$sth =
		  $dbh->prepare( "SELECT count(*) FROM "
			  . SQL_ADMIN_TABLE
			  . " WHERE type='asban' AND sval1 = ?;" )
		  or make_error(S_SQLFAIL);
		$sth->execute($as_num) or make_error(S_SQLFAIL);

		make_ban(S_BADHOST, {ip => $ip, showmask => 0, reason => S_ASBAN})
			if (($sth->fetchrow_array())[0]);
	}

	# check if the IP (ival1) belongs to a banned IP range (ival2)
	# also checks expired (sval2) and fetches the ban reason(s) (comment)
	my @bans = ();
	# current board or all boards (TODO: support list of boards)
	my $board = decode_string(BOARD_IDENT, CHARSET);

	if ($ip =~ /:/) { # IPv6
		my $client_ip = new Net::IP($ip) or make_error(Net::IP::Error());

		# fetch all active bans from the database, regardless of actual IP version and range
		$sth =
		  $dbh->prepare( "SELECT comment,ival1,ival2,sval1 FROM "
			  . SQL_ADMIN_TABLE
			  . " WHERE type='ipban'"
			  . " AND LENGTH(ival1)>10"
			  . " AND (boards IS NULL OR boards=?)"
			  . " AND (CAST(sval1 AS UNSIGNED)>? OR sval1='')"
			  . " ORDER BY num;" )
		  or make_error(S_SQLFAIL);
		$sth->execute($board, time()) or make_error(S_SQLFAIL);

		while ($row = get_decoded_hashref($sth)) {
			# ignore IPv4 addresses
			if (length(pack('w', $$row{ival1})) > 5) {
				my $banned_ip = new Net::IP(dec_to_dot($$row{ival1})) or make_error(Net::IP::Error());
				my $mask_len = get_mask_len($$row{ival2});

				# compare binary strings of $banned_ip and $client_ip up to mask length
				my $client_bits = substr($client_ip->binip(), 0, $mask_len);
				my $banned_bits = substr($banned_ip->binip(), 0, $mask_len);
				if ($client_bits eq $banned_bits) {
					# fill $banned_bits with 0 to get a valid 128 bit IPv6 address mask
					$banned_bits .= ('0' x (128 - $mask_len));

					my ($ban);
					$$ban{ip}       = $ip;
					$$ban{network}  = ip_compress_address(ip_bintoip($banned_bits, 6), 6);
					$$ban{setbits}  = $mask_len;
					$$ban{showmask} = $$ban{setbits} < 128 ? 1 : 0;
					$$ban{reason}   = resolve_reflinks($$row{comment});
					$$ban{expires}  = $$row{sval1};
					push @bans, $ban;
				}
			}
		}
	} else { # IPv4 using MySQL 5 (64 bit BIGINT) bitwise logic
		$sth =
		  $dbh->prepare( "SELECT comment,ival2,sval1 FROM "
			  . SQL_ADMIN_TABLE
			  . " WHERE type='ipban'"
			  . " AND LENGTH(ival1)<=10"
			  . " AND (boards IS NULL OR boards=?)"
			  . " AND ? & ival2 = ival1 & ival2"
			  . " AND (CAST(sval1 AS UNSIGNED)>? OR sval1='')"
			  . " ORDER BY num;" )
		  or make_error(S_SQLFAIL);
		$sth->execute($board, $numip, time()) or make_error(S_SQLFAIL);

		while ($row = get_decoded_hashref($sth)) {
			my ($ban);
			$$ban{ip}       = $ip;
			$$ban{network}  = dec_to_dot($numip & $$row{ival2});
			$$ban{setbits}  = unpack("%32b*", pack('N', $$row{ival2}));
			$$ban{showmask} = $$ban{setbits} < 32 ? 1 : 0;
			$$ban{reason}   = resolve_reflinks($$row{comment});
			$$ban{expires}  = $$row{sval1};
			push @bans, $ban;
		}
	}

	# this will send the ban message(s) to the client
    make_ban(S_BADHOST, @bans) if (@bans);

# fucking mysql...
#	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_ADMIN_TABLE
#	  ." WHERE type='wordban' AND ? LIKE '%' || sval1 || '%';") or make_error(S_SQLFAIL);
#	$sth->execute($comment) or make_error(S_SQLFAIL);
#
#	make_error(S_STRREF) if(($sth->fetchrow_array())[0]);

    $sth =
      $dbh->prepare( "SELECT sval1,comment FROM "
          . SQL_ADMIN_TABLE
          . " WHERE type='wordban';" )
      or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

    while ( $row = $sth->fetchrow_arrayref() ) {
        my $regexp = quotemeta $$row[0];
        make_error(S_STRREF) if ($comment =~ /$regexp/);
        make_error(S_STRREF) if ($name    =~ /$regexp/);
        make_error(S_STRREF) if ($subject =~ /$regexp/);
    }

    # etc etc etc

    return (0);
}

sub flood_check {
    my ( $ip, $time, $comment, $file, $parent ) = @_;
    my ( $sth, $maxtime );

    if ($file) {

        # check for to quick file posts
        $maxtime = $time - (RENZOKU2);
        $sth =
          $dbh->prepare( "SELECT count(*) FROM "
              . SQL_TABLE
              . " WHERE ip=? AND timestamp>$maxtime;" )
          or make_error(S_SQLFAIL);
        $sth->execute($ip) or make_error(S_SQLFAIL);
        make_error(S_RENZOKU2) if ( ( $sth->fetchrow_array() )[0] );
    }
    else {

        # check for too quick replies or text-only posts
        $maxtime = $time - (RENZOKU);
        $sth =
          $dbh->prepare( "SELECT count(*) FROM "
              . SQL_TABLE
              . " WHERE ip=? AND timestamp>$maxtime;" )
          or make_error(S_SQLFAIL);
        $sth->execute($ip) or make_error(S_SQLFAIL);
        make_error(S_RENZOKU) if ( ( $sth->fetchrow_array() )[0] );

        # check for repeated messages
        $maxtime = $time - (RENZOKU3);
        $sth =
          $dbh->prepare( "SELECT count(*) FROM "
              . SQL_TABLE
              . " WHERE ip=? AND comment=? AND timestamp>$maxtime;" )
          or make_error(S_SQLFAIL);
        $sth->execute( $ip, $comment ) or make_error(S_SQLFAIL);
        make_error(S_RENZOKU3) if ( ( $sth->fetchrow_array() )[0] );
    }

	if (!$parent) {

		# check for too many threads in the last 30 minutes
        $maxtime = $time - 1800;
        $sth =
          $dbh->prepare( "SELECT count(*) FROM "
              . SQL_TABLE
              . " WHERE parent=0 AND ip=? AND timestamp>$maxtime;" )
          or make_error(S_SQLFAIL);
        $sth->execute($ip) or make_error(S_SQLFAIL);
        make_error(S_RENZOKU5) if ( ( $sth->fetchrow_array() )[0] >= RENZOKU5 );
	}
}



sub format_comment {
    my ($comment) = @_;

	# filter comment
	$comment = apply_wordfilter($comment);

	# convert full URLs to internal cross board references
	$comment =~ s!${\BASE_URL}/([\wäöü]+)/thread/(?:[0-9]+#)?([0-9]+)!&gt;&gt;/$1/$2!g if (BASE_URL);

    # hide >>1 references from the quoting code
    $comment =~ s/&gt;&gt;([0-9\-]+)/&gtgt;$1/g;
    $comment =~ s|&gt;&gt;(/[\wäöü]+/[0-9\-]+)|&gtgt;$1|g;

    my $handler = sub    # mark >>1 references
    {
        my $line = shift;

		# references are prefixed with a html comment and will be resolved on
		# every page creation to support links to deleted (and also future) posts
		$line =~ s/&gtgt;([0-9]+)/<!--reflink-->&gt;&gt;$1/g;
		$line =~ s|&gtgt;(/[\wäöü]+/[0-9]+)|<!--reflink-->&gt;&gt;$1|g;

        return $line;
    };


	if (ENABLE_WAKABAMARK) {
		$comment = do_wakabamark($comment, $handler);
	} elsif (ENABLE_BBCODE) {
		# do_bbcode() will always try to apply (at least some) wakabamark
		$comment = do_bbcode($comment, $handler);
	} else {
		$comment = "<p>" . simple_format($comment, $handler) . "</p>";
	}

    # fix <blockquote> styles for old stylesheets
    $comment =~ s/<blockquote>/<blockquote class="unkfunc">/g;

    # restore >>1 references hidden in code blocks
    $comment =~ s/&gtgt;/&gt;&gt;/g;

    return $comment;
}

sub simple_format {
    my ( $comment, $handler ) = @_;
    return join "<br />", map {
        my $line = $_;

        # make URLs into links
        $line =~
s{(https?://[^\s<>"]*?)((?:\s|<|>|"|\.|\)|\]|!|\?|,|&#44;|&quot;)*(?:[\s<>"]|$))}{\<a target="_blank" href="$1" rel="nofollow"\>$1\</a\>$2}sgi;

        # colour quoted sections if working in old-style mode.
        $line =~ s!^(&gt;.*)$!\<span class="unkfunc"\>$1\</span\>!g
          unless (ENABLE_WAKABAMARK);

        $line = $handler->($line) if ($handler);

        $line;
    } split /\n/, $comment;
}

sub encode_string {
    my ($str) = @_;

    return $str unless ($has_encode);
    return encode( CHARSET, $str, 0x0400 );
}

sub make_anonymous {
    my ( $ip, $time ) = @_;

    return S_ANONAME unless (SILLY_ANONYMOUS);

    my $string = $ip;
    $string .= "," . int( $time / 86400 ) if ( SILLY_ANONYMOUS =~ /day/i );
    $string .= "," . BOARD_IDENT if ( SILLY_ANONYMOUS =~ /board/i );

    srand unpack "N", hide_data( $string, 4, "silly", SECRET );

    return cfg_expand(
        "%G% %W%",
        W => [
            "%B%%V%%M%%I%%V%%F%", "%B%%V%%M%%E%",
            "%O%%E%",             "%B%%V%%M%%I%%V%%F%",
            "%B%%V%%M%%E%",       "%O%%E%",
            "%B%%V%%M%%I%%V%%F%", "%B%%V%%M%%E%"
        ],
        B => [
            "B",  "B",  "C",  "D",  "D", "F", "F", "G", "G",  "H",
            "H",  "M",  "N",  "P",  "P", "S", "S", "W", "Ch", "Br",
            "Cr", "Dr", "Bl", "Cl", "S"
        ],
        I => [
            "b", "d", "f", "h", "k",  "l", "m", "n",
            "p", "s", "t", "w", "ch", "st"
        ],
        V => [ "a", "e", "i", "o", "u" ],
        M => [
            "ving",  "zzle",  "ndle",  "ddle",  "ller", "rring",
            "tting", "nning", "ssle",  "mmer",  "bber", "bble",
            "nger",  "nner",  "sh",    "ffing", "nder", "pper",
            "mmle",  "lly",   "bling", "nkin",  "dge",  "ckle",
            "ggle",  "mble",  "ckle",  "rry"
        ],
        F => [
            "t",  "ck",  "tch", "d",   "g",   "n",
            "t",  "t",   "ck",  "tch", "dge", "re",
            "rk", "dge", "re",  "ne",  "dging"
        ],
        O => [
            "Small",    "Snod",   "Bard",    "Billing",
            "Black",    "Shake",  "Tilling", "Good",
            "Worthing", "Blythe", "Green",   "Duck",
            "Pitt",     "Grand",  "Brook",   "Blather",
            "Bun",      "Buzz",   "Clay",    "Fan",
            "Dart",     "Grim",   "Honey",   "Light",
            "Murd",     "Nickle", "Pick",    "Pock",
            "Trot",     "Toot",   "Turvey"
        ],
        E => [
            "shaw",  "man",   "stone", "son",   "ham",   "gold",
            "banks", "foot",  "worth", "way",   "hall",  "dock",
            "ford",  "well",  "bury",  "stock", "field", "lock",
            "dale",  "water", "hood",  "ridge", "ville", "spear",
            "forth", "will"
        ],
        G => [
            "Albert",    "Alice",     "Angus",     "Archie",
            "Augustus",  "Barnaby",   "Basil",     "Beatrice",
            "Betsy",     "Caroline",  "Cedric",    "Charles",
            "Charlotte", "Clara",     "Cornelius", "Cyril",
            "David",     "Doris",     "Ebenezer",  "Edward",
            "Edwin",     "Eliza",     "Emma",      "Ernest",
            "Esther",    "Eugene",    "Fanny",     "Frederick",
            "George",    "Graham",    "Hamilton",  "Hannah",
            "Hedda",     "Henry",     "Hugh",      "Ian",
            "Isabella",  "Jack",      "James",     "Jarvis",
            "Jenny",     "John",      "Lillian",   "Lydia",
            "Martha",    "Martin",    "Matilda",   "Molly",
            "Nathaniel", "Nell",      "Nicholas",  "Nigel",
            "Oliver",    "Phineas",   "Phoebe",    "Phyllis",
            "Polly",     "Priscilla", "Rebecca",   "Reuben",
            "Samuel",    "Sidney",    "Simon",     "Sophie",
            "Thomas",    "Walter",    "Wesley",    "William"
        ],
    );
}

sub make_id_code {
    my ( $ip, $time, $link ) = @_;

    return EMAIL_ID if ( $link and DISPLAY_ID =~ /link/i );
    return EMAIL_ID if ( $link =~ /sage/i and DISPLAY_ID =~ /sage/i );

	# replaced $ENV{REMOTE_ADDR} by get_remote_addr()
    return resolve_host( get_remote_addr() ) if ( DISPLAY_ID =~ /host/i );
    return get_remote_addr() if ( DISPLAY_ID =~ /ip/i );

    my $string = "";
    $string .= "," . int( $time / 86400 ) if ( DISPLAY_ID =~ /day/i );
    $string .= "," . BOARD_IDENT if ( DISPLAY_ID =~ /board/i );

    return mask_ip( get_remote_addr(), make_key( "mask", SECRET, 32 ) . $string )
      if ( DISPLAY_ID =~ /mask/i );

    return hide_data( $ip . $string, 6, "id", SECRET, 1 );
}

sub get_post {
    my ($thread) = @_;
    my ($sth);

    $sth = $dbh->prepare("SELECT num,parent FROM " . SQL_TABLE . " WHERE num=?;")
      or make_error(S_SQLFAIL);
    $sth->execute($thread) or make_error(S_SQLFAIL);

    return $sth->fetchrow_hashref();
}

sub get_parent_post {
    my ($thread) = @_;
    my ($sth);

    $sth = $dbh->prepare(
        "SELECT * FROM " . SQL_TABLE . " WHERE num=? AND parent=0;" )
      or make_error(S_SQLFAIL);
    $sth->execute($thread) or make_error(S_SQLFAIL);

    return $sth->fetchrow_hashref();
}

sub get_board_post {
	my ($board, $post) = @_;
	my ($sth, $contents);
	$board =~ s/[\*<>|?&]//g; # remove special characters
	$board =~ s/.*[\\\/]//; # remove any leading path

	my $cfgfile = $board . "/config.pl";
	return 0 unless (-d $board and -f $cfgfile);

	open BOARDCFG, $cfgfile or return 0;
	$contents .= $_ while (<BOARDCFG>);
	close BOARDCFG;

	if ($contents =~
		/^\s*use\s+constant\s+SQL_TABLE\s*=>\s*(?:'|")([^'"]+)(?:'|")\s*;/m ) {

		$sth = $dbh->prepare("SELECT num,parent FROM " . $1 . " WHERE num=?;")
			or make_error(S_SQLFAIL);
		$sth->execute($post) or make_error(S_SQLFAIL);

		return $sth->fetchrow_hashref();
	}
	return 0;
}

sub sage_count {
    my ($parent) = @_;
    my ($sth);

    $sth =
      $dbh->prepare( "SELECT count(*) FROM "
          . SQL_TABLE
          . " WHERE parent=? AND NOT ( timestamp<? AND ip=? );" )
      or make_error(S_SQLFAIL);
    $sth->execute( $$parent{num}, $$parent{timestamp} + (NOSAGE_WINDOW),
        $$parent{ip} )
      or make_error(S_SQLFAIL);

    return ( $sth->fetchrow_array() )[0];
}

sub get_file_size {
    my ($file) = @_;
	my (@filestats, $errfname, $errfsize, $max_size);
    my ($size) = 0;
    my ($ext) = $file =~ /\.([^\.]+)$/;
    my %sizehash = FILESIZES;

	@filestats = stat($file);
	$size = $filestats[7];
	$max_size = MAX_KB;
	$max_size = $sizehash{$ext} if ($sizehash{$ext});
	$errfname = clean_string(decode_string($file, CHARSET));
	# or round using: int($size / 1024 + 0.5)
	$errfsize = sprintf("%.2f", $size / 1024) . " kB &gt; " . $max_size . " kB";

    make_error(S_TOOBIG . " ($errfname: $errfsize)") if ($size > $max_size * 1024);
    make_error(S_TOOBIGORNONE . " ($errfname)") if ($size == 0);  # check for small files, too?

    return ($size);
}


sub get_preview {
    my ($comment) = @_;
    my $preview;
# remove linebreaks
    $comment =~ s/\r?\n|\r\n|\r|\n/ /g;
# remove control chars
    $comment =~ s/[\000-\037]/ /g;
# remove smiley expressions
	$comment =~ s/\:[A-Za-z]+\:/ /g;
# shorten string
    $preview = substr($comment, 0, 70);
# append ... if too long
	if (length($comment) > 70) {
		$preview .= "...";
	}
    return $preview;
}


sub process_file {
    my ( $file, $uploadname, $time ) = @_;
    my %filetypes = FILETYPES;

# make sure to read file in binary mode on platforms that care about such things
    binmode $file;

	$uploadname = 'fefe' if ref($file) eq 'GLOB'; # fefe hack - other files have 'CGI::File::Temp'

    # analyze file and check that it's in a supported format
    my ( $ext, $width, $height ) = analyze_image( $file, $uploadname );

    #my ($known,$ext,$width,$height) = analyze_file($file, $uploadname);

    my $known = ( $width or $filetypes{$ext} );
	my $errfname = clean_string(decode_string($uploadname, CHARSET));

    make_error(S_BADFORMAT . ' ('.$errfname.')') unless ( ALLOW_UNKNOWN or $known );
    make_error(S_BADFORMAT . ' ('.$errfname.')') if ( grep { $_ eq $ext } FORBIDDEN_EXTENSIONS );
    make_error(S_TOOBIG . ' ('.$errfname.')') if ( MAX_IMAGE_WIDTH  and $width > MAX_IMAGE_WIDTH );
    make_error(S_TOOBIG . ' ('.$errfname.')') if ( MAX_IMAGE_HEIGHT and $height > MAX_IMAGE_HEIGHT );
    make_error(S_TOOBIG . ' ('.$errfname.')')
      if ( MAX_IMAGE_PIXELS and $width * $height > MAX_IMAGE_PIXELS );

	# jpeg -> jpg
	$uploadname =~ s/\.jpeg$/\.jpg/i;

	# make sure $uploadname file extension matches detected extension (for internal formats)
	my ($uploadext) = $uploadname =~ /\.([^\.]+)$/;
	$uploadname .= "." . $ext if (lc($uploadext) ne $ext);

    # generate random filename - fudges the microseconds
    my $filebase  = $time . sprintf("-%03d", int(rand(1000)));
    my $filename  = BOARD_IDENT . '/' . IMG_DIR . $filebase . '.' . $ext;
    my $thumbnail = BOARD_IDENT . '/' . THUMB_DIR . $filebase;
	if ( $ext eq "png" )
	{
		$thumbnail .= "s.png";
	}
	elsif ( $ext eq "gif" )
	{
		$thumbnail .= "s.gif";
	}
	else
	{
		$thumbnail .= "s.jpg";
	}

    $filename .= MUNGE_UNKNOWN unless ($known);

    # do copying and MD5 checksum
    my ( $md5, $md5ctx, $buffer );

    # prepare MD5 checksum if the Digest::MD5 module is available
    eval 'use Digest::MD5 qw(md5_hex)';
    $md5ctx = Digest::MD5->new unless ($@);

    # copy file
    open( OUTFILE, ">>$filename" ) or make_error(S_NOTWRITE . " ($filename)");
    binmode OUTFILE;
    while ( read( $file, $buffer, 1024 ) )    # should the buffer be larger?
    {
        print OUTFILE $buffer;
        $md5ctx->add($buffer) if ($md5ctx);
    }
    close $file;
    close OUTFILE;

#	if($md5ctx) # if we have Digest::MD5, get the checksum
#	{
#		$md5=$md5ctx->hexdigest();
#	}
#	else # otherwise, try using the md5sum command
#	{
#		my $md5sum=`md5sum $filename`; # filename is always the timestamp name, and thus safe
#		($md5)=$md5sum=~/^([0-9a-f]+)/ unless($?);
#	}

#	if($md5) # if we managed to generate an md5 checksum, check for duplicate files
#	{
#		my $sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE md5=?;") or make_error(S_SQLFAIL);
#		$sth->execute($md5) or make_error(S_SQLFAIL);
#
#		if(my $match=$sth->fetchrow_hashref())
#		{
#			unlink $filename; # make sure to remove the file
#			make_error(sprintf(S_DUPE,get_reply_link($$match{num},$$match{parent})));
#		}
#	}

    # do thumbnail
    my ( $tn_width, $tn_height, $tn_ext );

    if ( !$width )    # unsupported file
    {
#        if ( $filetypes{$ext} )                 # externally defined filetype
#        {
#            open THUMBNAIL, $filetypes{$ext};
#            binmode THUMBNAIL;
#            ( $tn_ext, $tn_width, $tn_height ) =
#              analyze_image( \*THUMBNAIL, $filetypes{$ext} );
#            close THUMBNAIL;
#
#            # was that icon file really there?
#            if   ( !$tn_width ) { $thumbnail = undef }
#            else                { $thumbnail = $filetypes{$ext} }
#        }
#        else {
            $thumbnail = undef;
#        }
    }
    elsif ($width > MAX_W
        or $height > MAX_H
        or THUMBNAIL_SMALL
		or $ext eq 'pdf'
		or $ext eq 'webm'
		or $ext eq 'mp4')
    {
        if ( $width <= MAX_W and $height <= MAX_H ) {
            $tn_width  = $width;
            $tn_height = $height;
        }
        else {
            $tn_width = MAX_W;
            $tn_height = int( ( $height * (MAX_W) ) / $width );

            if ( $tn_height > MAX_H ) {
                $tn_width = int( ( $width * (MAX_H) ) / $height );
                $tn_height = MAX_H;
            }
        }

		if ($ext eq 'pdf') { # cannot determine dimensions
			undef($width);
			undef($height);
			$tn_width = MAX_W;
			$tn_height = MAX_H;				
		}

        if (STUPID_THUMBNAILING) {
			$thumbnail = $filename;
			undef($thumbnail) if ($ext eq 'pdf' or $ext eq 'webm' or $ext eq 'mp4');
		}
        else {
			if ($ext eq 'webm' or $ext eq 'mp4') {
				undef($thumbnail)
				  unless (
					make_video_thumbnail(
						$filename,         $thumbnail,
						$tn_width,         $tn_height,
						VIDEO_CONVERT_COMMAND
					)
				  );
			}
			else {
				undef($thumbnail)
				  unless (
					make_thumbnail(
						$filename,         $thumbnail,
						$tn_width,         $tn_height,
						THUMBNAIL_QUALITY, CONVERT_COMMAND
					)
				  );
			}

			# get the thumbnail size created by external program
			if ($thumbnail and ($ext eq 'pdf')) {
				open THUMBNAIL,$thumbnail;
				binmode THUMBNAIL;
				($tn_ext, $tn_width, $tn_height) = analyze_image(\*THUMBNAIL, $thumbnail);
				close THUMBNAIL;
			}
        }
    }
    else {
        $tn_width  = $width;
        $tn_height = $height;
        $thumbnail = $filename;
    }

    #	if($filetypes{$ext}) # externally defined filetype - restore the name
    #	{
    #		my $newfilename=$uploadname;
    #		$newfilename=~s!^.*[\\/]!!; # cut off any directory in filename
    #		$newfilename=IMG_DIR.$newfilename;
    #
    #		unless(-e $newfilename) # verify no name clash
    #		{
    #			rename $filename,$newfilename;
    #			$thumbnail=$newfilename if($thumbnail eq $filename);
    #			$filename=$newfilename;
    #		}
    #		else
    #		{
    #			unlink $filename;
    #			make_error(S_DUPENAME);
    #		}
    #	}

	my ($info, $info_all) = get_meta_markup($filename, CHARSET, TOOLTIP_TAGS);
	return ($filename, $md5, $width, $height, $thumbnail, $tn_width, $tn_height,
		$info, $info_all, $uploadname);
}

#
# Deleting
#

sub delete_stuff {
    my ( $password, $fileonly, $admin, $parent, @posts ) = @_;
    my ($post);
    my $deletebyip = 0;
	my $noko = 1; # try to stay in thread after deletion by default

	my ($stafftype, $staffid) = check_session($admin, 1);

	# clean up invalid admin cookie/session or deletion would always fail
	$admin = "" unless ($stafftype);

    check_password( $admin, ADMIN_PASS ) if ($admin);

    if ( !$password and !$admin ) { $deletebyip = 1; }

    # no password means delete always
    $password = "" if ($admin);

    make_error(S_BADDELPASS)
      unless ( ( !$password and $deletebyip ) # allow deletion by ip with empty password
        or ( $password and !$deletebyip )
        or $admin );

    foreach $post (@posts) {
        delete_post( $post, $password, $fileonly, $deletebyip, $admin, $staffid );
		$noko = 0 if ( $parent and $post eq $parent ); # thread deleted and cannot be redirected to
    }

    if ($admin) {
        make_http_forward(get_script_name() . "?task=show&board=" . get_board_id());
    } elsif ( $noko == 1 and $parent ) {
		make_http_forward(get_board_id() . "/thread/" . $parent);
	} else { make_http_forward(get_board_id() . "/"); }
}

sub make_kontra {
    my ( $admin, $threadid ) = @_;

    my ($stafftype, $staffid) = check_session($admin);

    my ( $sth, $row );
    $sth = $dbh->prepare( "SELECT * FROM " . SQL_TABLE . " WHERE num=?;" )
      or make_error(S_SQLFAIL);
    $sth->execute($threadid) or make_error(S_SQLFAIL);

    if ( $row = $sth->fetchrow_hashref() ) {
        my $kontra = $$row{autosage} eq 1 ? 0 : 1;
        my $sth2;
        $sth2 = $dbh->prepare(
            "UPDATE " . SQL_TABLE . " SET autosage=? WHERE num=?;" )
          or make_error(S_SQLFAIL);
        $sth2->execute( $kontra, $threadid ) or make_error(S_SQLFAIL);

		add_log_entry("Thread bumplock", $staffid, $threadid) if ($kontra == 1);
		add_log_entry("Thread bump unlock", $staffid, $threadid) if ($kontra == 0);
    }

    make_http_forward(get_script_name() . "?task=show&board=" . get_board_id());
}

sub make_locked {
    my ( $admin, $threadid ) = @_;

    my ($stafftype, $staffid) = check_session($admin);

    my ( $sth, $row );
    $sth = $dbh->prepare( "SELECT * FROM " . SQL_TABLE . " WHERE num=?;" )
      or make_error(S_SQLFAIL);
    $sth->execute($threadid) or make_error(S_SQLFAIL);

    if ( $row = $sth->fetchrow_hashref() ) {
        my $locked = $$row{locked} eq 1 ? 0 : 1;
        my $sth2;
        $sth2 = $dbh->prepare(
            "UPDATE " . SQL_TABLE . " SET locked=? WHERE num=?;" )
          or make_error(S_SQLFAIL);
        $sth2->execute( $locked, $threadid ) or make_error(S_SQLFAIL);

		add_log_entry("Thread lock", $staffid, $threadid) if ($locked == 1);
		add_log_entry("Thread unlock", $staffid, $threadid) if ($locked == 0);
    }

    make_http_forward(get_script_name() . "?task=show&board=" . get_board_id());
}

sub make_sticky {
    my ( $admin, $threadid ) = @_;

    my ($stafftype, $staffid) = check_session($admin);

    my ( $sth, $row );
    $sth = $dbh->prepare( "SELECT * FROM " . SQL_TABLE . " WHERE num=?;" )
      or make_error(S_SQLFAIL);
    $sth->execute($threadid) or make_error(S_SQLFAIL);

    if ( $row = $sth->fetchrow_hashref() ) {
        my $sticky = $$row{sticky} eq 1 ? undef : 1;
        my $sth2;
        $sth2 = $dbh->prepare(
            "UPDATE " . SQL_TABLE . " SET sticky=? WHERE num=? OR parent=?;" )
          or make_error(S_SQLFAIL);
        $sth2->execute( $sticky, $threadid, $threadid) or make_error(S_SQLFAIL);

		add_log_entry("Thread sticky", $staffid, $threadid) if ($sticky == 1);
		add_log_entry("Thread unsticky", $staffid, $threadid) if ($sticky == undef);
    }

    make_http_forward(get_script_name() . "?task=show&board=" . get_board_id());
}

sub delete_post {
    my ( $post, $password, $fileonly, $deletebyip, $admin, $staffid ) = @_;
    my ( $sth, $row, $res, $reply );

	# this has already been checked in delete_stuff and does not seem to be neccessary here
	check_password($admin, ADMIN_PASS) if ($admin);

    my $thumb   = THUMB_DIR;
    my $src     = IMG_DIR;
    my $numip   = dot_to_dec(get_remote_addr()); # do not use $ENV{REMOTE_ADDR}
    $sth = $dbh->prepare( "SELECT * FROM " . SQL_TABLE . " WHERE num=?;" )
      or make_error(S_SQLFAIL);
    $sth->execute($post) or make_error(S_SQLFAIL);

    if ( $row = $sth->fetchrow_hashref() ) {
        make_error(S_BADDELPASS)
          if ( $password and $$row{password} ne $password );
        make_error(S_BADDELIP)
          if ( $deletebyip and ( $numip and $$row{ip} ne $numip ) );
		# corner case: a system trim action could be prevented by wrong settings
		make_error(S_RENZOKU4)
		  if ( $$row{timestamp} + RENZOKU4 >= time() and !$admin );

		# logging
		my $posttype = $$row{parent} == 0 ? "thread" : "post";

		if ($admin) {
			# do not log deletion of own posts (by ip)
			# a valid staff session will cause $password to be empty
			# so only matching ip can be checked
			if ($$row{ip} ne $numip or $$row{ip} eq "0") {
				# never log staff IP address
				$$row{ip} = undef if $$row{adminpost};
				if ($fileonly) {
					add_log_entry("Delete files", $staffid, $post);
				} else {
					add_log_entry("Delete " . $posttype, $staffid, $post, $$row{comment}, $$row{ip});
				}
			} else {
				# debug logging: staff deletion of own posts
				if ($fileonly) {
					add_log_entry("Delete own files", $staffid, $post);
				} else {
					add_log_entry("Delete own " . $posttype, $staffid, $post, $$row{comment});
				}
			}
		} else {
			# debug logging: user deletion of own posts
			if ($fileonly) {
				add_log_entry("Delete own files", undef, $post);
			} else {
				if (!$password and !$deletebyip) {
					my $logdata = "[created " . make_date($$row{timestamp}, '2ch') . " / lasthit "
						. make_date($$row{lasthit}, '2ch')  . "] " . $$row{comment};
					add_log_entry("System trim " . $posttype, undef, $post, $logdata, $$row{ip});
				} else {
					add_log_entry("Delete own " . $posttype, undef, $post, $$row{comment}, $$row{ip});
				}
			}
		}

		# deletion
        unless ($fileonly) {

            # remove files from comment and possible replies
            $sth = $dbh->prepare(
                    "SELECT image, thumbnail FROM " . SQL_TABLE_IMG . " WHERE post=? OR thread=?;" )
              or make_error(S_SQLFAIL);
            $sth->execute( $post, $post ) or make_error(S_SQLFAIL);

            while ( $res = $sth->fetchrow_hashref() ) {
				$$res{image} =~ s!.*/!!;
				$$res{thumbnail} =~ s!.*/!!;
				# delete images if they exist
				unlink BOARD_IDENT . '/' . IMG_DIR . $$res{image};
				unlink BOARD_IDENT . '/' . THUMB_DIR . $$res{thumbnail}; # if ( $$res{thumbnail} =~ /^$thumb/ );
            }

            # remove post and possible replies
            $sth = $dbh->prepare(
                "DELETE FROM " . SQL_TABLE . " WHERE num=? OR parent=?;" )
              or make_error(S_SQLFAIL);
            $sth->execute( $post, $post ) or make_error(S_SQLFAIL);

            $sth = $dbh->prepare(
                "DELETE FROM " . SQL_TABLE_IMG . " WHERE post=? OR thread=?;" )
              or make_error(S_SQLFAIL);
            $sth->execute( $post, $post ) or make_error(S_SQLFAIL);

			# prevent GHOST BUMPING by hanging a thread where it belongs:
			# at the time of the last non sage post
            if (PREVENT_GHOST_BUMPING) {

                # get parent of the deleted post
				# if a thread was deleted, nothing needs to be done
                my $parent = $$row{parent};
                if ($parent) {

                    # its actually a post in a thread, not a thread itself
                    # find the thread to check for autosage
                    $sth = $dbh->prepare(
                        "SELECT * FROM " . SQL_TABLE . " WHERE num=?;" )
                      or make_error(S_SQLFAIL);
                    $sth->execute($parent) or make_error(S_SQLFAIL);
                    my $threadRow = $sth->fetchrow_hashref();
                    if ( $threadRow and $$threadRow{autosage} != 1 ) {
						# store the thread OP timestamp value
						# will be used if no non-sage reply is found
						my $lasthit = $$threadRow{timestamp};
                        my $sth2;
                        $sth2 =
                          $dbh->prepare( "SELECT * FROM "
                              . SQL_TABLE
                              . " WHERE parent=? ORDER BY timestamp DESC;"
                          ) or make_error(S_SQLFAIL);
                        $sth2->execute($parent) or make_error(S_SQLFAIL);
                        my $postRow;
                        my $foundLastNonSage = 0;
                        while ( ( $postRow = $sth2->fetchrow_hashref() )
                            and $foundLastNonSage == 0 )
                        {
                            $foundLastNonSage = $$postRow{timestamp}
								if ($$postRow{email} !~ /sage/i);
                        }

						# var now contains the timestamp we have to update lasthit to
						$lasthit = $foundLastNonSage if ($foundLastNonSage);

                        my $upd;
                        $upd =
                          $dbh->prepare( "UPDATE "
                              . SQL_TABLE
                              . " SET lasthit=? WHERE parent=? OR num=?;" )
                          or make_error(S_SQLFAIL);
                        $upd->execute( $lasthit, $parent, $parent )
                          or make_error( S_SQLFAIL . " " . $dbh->errstr() );
                    }
                }
            }

        }
        else    # remove just the image(s) and update the database
        {
            $sth = $dbh->prepare(
                    "SELECT image,thumbnail FROM " . SQL_TABLE_IMG . " WHERE post=?;" )
              or make_error(S_SQLFAIL);
            $sth->execute($post) or make_error(S_SQLFAIL);

            while ( $res = $sth->fetchrow_hashref() ) {
				$$res{image} =~ s!.*/!!;
				$$res{thumbnail} =~ s!.*/!!;
				# delete images if they exist
				unlink BOARD_IDENT . '/' . IMG_DIR . $$res{image};
				unlink BOARD_IDENT . '/' . THUMB_DIR . $$res{thumbnail}; # if ( $$res{thumbnail} =~ /^$thumb/ );
            }

			$sth = $dbh->prepare( "UPDATE "
				  . SQL_TABLE_IMG
				  . " SET size=0,md5=null,thumbnail=null,info=null,info_all=null WHERE post=?;" )
				or make_error(S_SQLFAIL);
			$sth->execute($post) or make_error(S_SQLFAIL);
        }
    }
}

sub add_log_entry {
	my ($event, $staff, $post, $comment, $ip) = @_;

	my $board = decode_string(BOARD_IDENT, CHARSET);

	$sth = $dbh->prepare( "INSERT INTO "
		. SQL_STAFF_LOG_TABLE
		. " VALUES(?,?,?,?,?,?,?);" )
		or make_error(S_SQLFAIL);
	$sth->execute(time(), $event, $board, $post, $staff, $ip, $comment)
		or make_error(S_SQLFAIL);
}

#
# Admin interface
#

sub make_admin_login {
    make_http_header();
    print encode_string( ADMIN_LOGIN_TEMPLATE->() );
}

sub make_admin_post_panel {
    my ($admin) = @_;

	my ($stafftype, $staffid, $staffname) = check_session($admin);
	make_error(S_NOPRIV) unless ($stafftype == 1);

	# geoip
	my $api = 'n/a';
	my $path = "/usr/local/share/GeoIP/";
	my @geo_dbs = qw(GeoIP.dat GeoIPv6.dat GeoLiteCity.dat GeoLiteCityv6.dat GeoIPASNum.dat GeoIPASNumv6.dat);
	my @results = ();

	eval 'use Geo::IP';
	unless ($@) {
		eval '$api = Geo::IP->api';

		$api .= ' (IPv6 lookups require CAPI)' unless ($api eq 'CAPI');

		foreach (@geo_dbs) {
			my ($gi, $geo_db);
			$$geo_db{file} = $_;
			$$geo_db{result} = 'n/a';
			eval '$gi = Geo::IP->open($path . "$_")';
			$$geo_db{result} = $gi->database_info unless ($@ or !$gi);
			push(@results, $geo_db);
		}
	}

	# statistics
	my ($sth, $row);
	my $threads = count_threads();
	my ($posts, $size) = count_posts();

    $sth = $dbh->prepare(
		"SELECT count(*) FROM " . SQL_TABLE_IMG . " WHERE image IS NOT NULL AND size>0;"
	) or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

    my $files = ($sth->fetchrow_array())[0];

	# "SELECT MIN(num), MIN(timestamp), MAX(num), MAX(timestamp) FROM " . SQL_TABLE
	$sth = $dbh->prepare(
		"SELECT num,timestamp FROM " . SQL_TABLE . " ORDER BY num ASC LIMIT 1;"
	) or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	$row = $sth->fetchrow_arrayref();
	my $oldest = $$row[0];
	my $o_date = $$row[1];

	$sth = $dbh->prepare(
		"SELECT num,timestamp FROM " . SQL_TABLE . " ORDER BY num DESC LIMIT 1;"
	) or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	$row = $sth->fetchrow_arrayref();
	my $newest = $$row[0];
	my $n_date = $$row[1];

    make_http_header();
    print encode_string(
        POST_PANEL_TEMPLATE->(
            admin    => $stafftype,
			staffname => $staffname,
            posts    => $posts,
            threads  => $threads,
            files    => $files,
            size     => $size,
            oldest   => $oldest,
            o_date   => $o_date,
            newest   => $newest,
            n_date   => $n_date,
            geoip_api      => $api,
            geoip_results  => \@results
        )
    );
}

sub get_staff_hashref {
    my ($sth, $row, %users);

	$sth = $dbh->prepare("SELECT num,user FROM " . SQL_STAFF_TABLE)
		or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	while ($row = get_decoded_hashref($sth)) {
		$users{$$row{num}} = $$row{user};
	}

	return \%users;
}

sub make_admin_ban_panel {
    my ($admin, $filter) = @_;
    my ( $sth, $row, @bans, $prevtype );

    my ($stafftype, $staffid, $staffname) = check_session($admin);

	my $users = get_staff_hashref();

	my $active = "";
	$active = " AND (sval1='' OR CAST(sval1 AS UNSIGNED)>?)" if ($filter ne "off");

    $sth =
      $dbh->prepare( "SELECT * FROM "
          . SQL_ADMIN_TABLE
          . " WHERE type='ipban'" . $active
		  . " OR type='wordban' OR type='whitelist' OR type='trust'"
		  . " OR type='asban' OR type='filter'"
		  . " ORDER BY type ASC, date DESC, num DESC;"
      ) or make_error(S_SQLFAIL);

	if ($active) {
		$sth->execute(time()) or make_error(S_SQLFAIL);
	} else {
		$sth->execute() or make_error(S_SQLFAIL);
	}

    while ( $row = get_decoded_hashref($sth) ) {
        $$row{divider} = 1 if ( $prevtype ne $$row{type} );
        $prevtype      = $$row{type};
        $$row{rowtype} = @bans % 2 + 1;
		if ($$row{type} eq 'ipban' or $$row{type} eq 'whitelist') {
			# add flag
			my $flag = get_geolocation(dec_to_dot($$row{ival1}));
			$flag = 'UNKNOWN' if ($flag eq 'unk' or $flag eq 'A1' or $flag eq 'A2');
			$$row{flag} = $flag;

			$$row{masklen} = get_mask_len($$row{ival2});
			## temporary check for ival2 (net mask) to make sure all existing database entries are valid
			## before the check in parse_range was introduced
			my $mask = dec_to_dot($$row{ival2});
			if ($mask =~ /:/) { # IPv6
				$mask = dot_to_dec($mask);
				my $binmask = $mask->as_bin();
				my $binlen = length($binmask); # must be 130
				my $maskok = $binmask =~ /^0b1+0*$/;
				$$row{masklen} .= ', invalid mask: ' . dec_to_dot($$row{ival2})
					unless ($binlen == 130 and $maskok);
			} else {            # IPv4
				$mask = dot_to_dec($mask);
				my $binmask = sprintf("%b", $mask);
				my $binlen = length($binmask); # must be 32
				my $maskok = $binmask =~ /^1+0*$/;
				$$row{masklen} .= ', invalid mask: ' . dec_to_dot($$row{ival2})
					unless ($binlen == 32 and $maskok);
			}
			## temporary check end
		}
		if ($$row{type} eq 'ipban') {
			# reflink in 'ipban' comments
			$$row{comment} = resolve_reflinks($$row{comment});
		}
		$$row{user} = $$users{$$row{staff}};
        push @bans, $row;
    }

    make_http_header();
    print encode_string(
        BAN_PANEL_TEMPLATE->(
			admin => $stafftype, staffname => $staffname, filter => $filter, bans => \@bans
		)
	);
}

sub make_admin_orphans {
    my ($admin) = @_;
	my ($sth, $row, @results, @dbfiles, @dbthumbs);

	my ($stafftype, $staffid, $staffname) = check_session($admin);
	make_error(S_NOPRIV) unless ($stafftype == 1);

	# gather all files/thumbs on disk
	my @files = glob BOARD_IDENT . '/' . IMG_DIR . '*';
	my @thumbs = glob BOARD_IDENT . '/' . THUMB_DIR . '*';

	# remove leading board path
	foreach my $item (@files) {
		$item =~ s!^[^/]+/!!;
	}
	foreach my $item (@thumbs) {
		$item =~ s!^[^/]+/!!;
	}

	# gather all files/thumbs from database
	$sth = $dbh->prepare(
		"SELECT image, thumbnail FROM "
		. SQL_TABLE_IMG .
		" WHERE size > 0 ORDER BY num ASC;"
	) or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	while ($row = get_decoded_arrayref($sth)) {
		$$row[0] =~ s!.*/!!;
		$$row[0] = IMG_DIR . $$row[0];
		push(@dbfiles, $$row[0]);

		if ($$row[1]) {
			$$row[1] =~ s!.*/!!;
			$$row[1] = THUMB_DIR . $$row[1];
			push(@dbthumbs, $$row[1])
		}
	}

	# copy all entries from the disk arrays that are not found in the database arrays to new arrays
	my %dbfiles_hash = map { $_ => 1 } @dbfiles;
	my %dbthumbs_hash = map { $_ => 1 } @dbthumbs;
	my @orph_files = grep { !$dbfiles_hash{$_} } @files;
	my @orph_thumbs = grep { !$dbthumbs_hash{$_} } @thumbs;

	my $file_count = @orph_files;
	my $thumb_count = @orph_thumbs;
	my @f_orph;
	my @t_orph;

	foreach my $file (@orph_files) {
		my @result = stat(BOARD_IDENT . '/' . $file);
		my $entry = {};
		$$entry{rowtype} = @f_orph % 2 + 1;
		$$entry{name} = $file;
		$$entry{modified} = $result[9];
		$$entry{size} = $result[7];
		push(@f_orph, $entry);
	}

	foreach my $thumb (@orph_thumbs) {
		my @result = stat(BOARD_IDENT . '/' . $thumb);
		my $entry = {};
		$$entry{name} = $thumb;
		$$entry{modified} = $result[9];
		$$entry{size} = $result[7];
		push(@t_orph, $entry);
	}

	make_http_header();
	print encode_string(ADMIN_ORPHANS_TEMPLATE->(
		admin       => $stafftype,
		staffname   => $staffname,
		files       => \@f_orph,
		thumbs      => \@t_orph,
		file_count  => $file_count,
		thumb_count => $thumb_count
	));
}

sub move_files($$){
	my ($admin, @files) = @_;
	my ($source, $target);

	make_error(S_NOPRIV) unless (check_session($admin))[0] == 1;

    foreach my $file (@files) {
		$file = clean_string($file);
		if ($file =~ m!^[a-zA-Z0-9]+/[a-zA-Z0-9-]+\.[a-zA-Z0-9]+$!) {
			$source = BOARD_IDENT . '/' . $file;
			$target = BOARD_IDENT . '/' . ORPH_DIR . $file;
			rename($source, $target)
				or make_error(S_NOTWRITE . ' (' . decode_string($target, CHARSET) . ')');
		}
	}

	make_http_forward(get_script_name() . "?task=orphans&board=" . get_board_id());
}

sub make_admin_edit_panel {
	my ($admin, $postid) = @_;
	my $row;

	my ($stafftype, $staffid, $staffname) = check_session($admin);

	make_error(S_UNUSUAL) if ($postid =~ /[^0-9]/);

	$sth = $dbh->prepare("SELECT name, subject, comment FROM " . SQL_TABLE . " WHERE num=?;")
	  or make_error(S_SQLFAIL);
	$sth->execute($postid) or make_error(S_SQLFAIL);

	if ($row = get_decoded_hashref($sth)) {
		# escape ampersand so browsers show the post text like it is stored in the db
		$$row{comment} = escamp($$row{comment});
		# add newlines for better readability but remove them on save!
		$$row{comment} =~ s!(<br />|</p>|</ul>|</li>|</blockquote>)!$1\n!g;

		$$row{comment} =~ s/</&lt;/g;
		$$row{comment} =~ s/>/&gt;/g;

		$sth->finish(); # record set not finished despite only one record exists

		make_http_header();
		print encode_string(ADMIN_EDIT_TEMPLATE->(
			admin   => $stafftype,
			staffname => $staffname,
			postid  => $postid,
			name    => $$row{name},
			subject => $$row{subject},
			comment => $$row{comment}
		));
	} else { make_error(S_NOREC); }
}

sub save_admin_edit {
	my ($admin, $postid, $name, $subject, $comment) = @_;
	my ($sth, $row);

	my ($stafftype, $staffid) = check_session($admin);

	# remove any newlines
	$name =~ s/\r\n|\n|\r//g;
	$subject =~ s/\r\n|\n|\r//g;
	$comment =~ s/\r\n|\n|\r//g;

	# decode and clean string inputs
	# could do even more checking (newlines, length) but admin is trusted
	$name = clean_string(decode_string($name, CHARSET));
	$subject = clean_string(decode_string($subject, CHARSET));
	$comment = decode_string($comment, CHARSET);

	# fetch old comment for logging
	$sth = $dbh->prepare("SELECT comment FROM " . SQL_TABLE . " WHERE num=?;")
	  or make_error(S_SQLFAIL);
	$sth->execute($postid) or make_error(S_SQLFAIL);
	$row = get_decoded_hashref($sth);

	$sth = $dbh->prepare("UPDATE " . SQL_TABLE . " SET name=?, subject=?, comment=? WHERE num=? LIMIT 1;" )
	  or make_error(S_SQLFAIL);
	$sth->execute($name, $subject, $comment, $postid) or make_error(S_SQLFAIL);

	add_log_entry("Edit post", $staffid, $postid, $$row{comment});

	make_http_forward(get_script_name() . "?task=show&board=" . get_board_id());
}

sub make_admin_log {
	my ($admin, $filter, $show) = @_;
	my ($sth, $row, @log, $reflink);

	my ($stafftype, $staffid, $staffname) = check_session($admin);

	my $users = get_staff_hashref();

	my $limit = "";
	$limit = " LIMIT 100" if (!$filter);

	$sth=$dbh->prepare("SELECT * FROM " . SQL_STAFF_LOG_TABLE . " ORDER BY timestamp DESC" . $limit . ";")
		or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	while ($row = get_decoded_hashref($sth)) {
		if ($$row{post}) {
			$reflink = '<!--reflink-->&gt;&gt;/' . $$row{board} . '/' . $$row{post};
			$$row{reflink} = resolve_reflinks($reflink);
		}

		# comment preview
		if ($$row{comment}) {
			my $preview = substr($$row{comment}, 0, 80);
			$preview =~ s/</&lt;/g;
			$preview =~ s/>/&gt;/g;
			#$preview .= " ..." if length($$row{comment}) > 80;
			$$row{preview} = $preview;
		}

		if ($show) {
			$$row{posttext} = resolve_reflinks($$row{comment});
			# do not show redundant information
			$$row{posttext} = undef if ($$row{posttext} eq $$row{preview});
		}

		$$row{user} = $$users{$$row{staff}};
		$$row{rowtype} = @log%2+1;
		push @log, $row;
	}

	# toggle flags for link output
	$show = $show ? 0 : 1;
	$filter = $filter ? 0 : 1;

	make_http_header();
	print encode_string(LOG_PANEL_TEMPLATE->(
		admin => $stafftype, staffname => $staffname, filter => $filter, show => $show, log => \@log
	));
}

sub make_admin_users {
	my ($admin) = @_;
	my ($sth, $row, @users, $prevtype);

	my ($stafftype, $staffid, $staffname) = check_session($admin);
	make_error(S_NOPRIV) unless ($stafftype == 1);

	$sth=$dbh->prepare("SELECT * FROM " . SQL_STAFF_TABLE . " ORDER BY type,user ASC;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	while ($row = get_decoded_hashref($sth)) {
		$$row{divider} = 1 if ($prevtype ne $$row{type});
		$prevtype = $$row{type};
		$$row{rowtype} = @users%2+1;
		push @users, $row;
	}

	make_http_header();
	print encode_string(STAFF_PANEL_TEMPLATE->(
		admin => 1, staffname => $staffname, current => $staffid, users => \@users
	));
}

sub do_login {
    my ($user, $password, $nexttask, $savelogin, $admincookie) = @_;
	my ($sth, $row, $session);

	my $numip = dot_to_dec(get_remote_addr());

	# login form was posted
    if ($user and $password) {

		$user = clean_string(decode_string($user, CHARSET));
		$password = crypt_password($password);

		$sth=$dbh->prepare("SELECT * FROM " . SQL_STAFF_TABLE . " WHERE user=?;")
		  or make_error(S_SQLFAIL);
		$sth->execute($user) or make_error(S_SQLFAIL);

		if ( $row = $sth->fetchrow_hashref()) {
			if ($$row{password} eq $password) {
				make_error(S_BADACCOUNT) unless $$row{enabled};

				$session = make_random_string(30);
				# check for collision - should never happen
				$sth = $dbh->prepare("SELECT 1 FROM " . SQL_STAFF_TABLE . " WHERE session=?;")
				  or make_error(S_SQLFAIL);
				$sth->execute($session) or make_error(S_SQLFAIL);
				make_error("Session error. Please reload the page.") if (($sth->fetchrow_array())[0]);

				$sth = $dbh->prepare("UPDATE " . SQL_STAFF_TABLE
					. " SET session=?, ip=?, timestamp=? WHERE num=?;") or make_error(S_SQLFAIL);
				$sth->execute($session, $numip, time(), $$row{num}) or make_error(S_SQLFAIL);
			} else { make_error(S_WRONGPASS) }
		} else { make_error(S_WRONGPASS) }
	}
	# silent session check to prepare redirect to default admin page
	elsif (check_session($admincookie, 1)) {
		$session = $admincookie;
		$nexttask = "show";
    }

	# a vaild session exists. create or update cookie.
	if ($session) {

	# TODO: clear old sessions
	# $sth=$dbh->prepare("UPDATE " . SQL_STAFF_TABLE
	#   . " SET session=null, ip=null WHERE timestamp<?;") or make_error(S_SQLFAIL);
	# $sth->execute(time() - 7 * 24 * 60 * 60) or make_error(S_SQLFAIL);

		my $expires = 0;
        if ($savelogin) {
			$expires = time() + 7 * 24 * 3600;
        }

		make_cookies(
			wakaadmin => $session,
			-charset  => CHARSET,
			-autopath => COOKIE_PATH,
			-expires  => $expires,
			-httponly => 1
		);

        make_http_forward(get_script_name() . "?task=$nexttask&board=" . get_board_id());
	}
	else { make_admin_login() }
}

sub do_logout {
	my ($session) = @_;

	$session = clean_string($session);

	if ($session) {
		my $sth;
		$sth = $dbh->prepare("UPDATE " . SQL_STAFF_TABLE . " SET session=null, ip=null WHERE session=?;")
			or make_error(S_SQLFAIL);
		$sth->execute($session) or make_error(S_SQLFAIL);
	}

    make_cookies( wakaadmin => "", -expires => 1 );
    make_http_forward(get_script_name() . "?task=admin&board=" . get_board_id());
}

sub add_admin_entry {
    my ($admin, $type, $comment, $ival1, $ival2, $sval1, $postid, $ajax, $flag, $icomment, $global,
		$delete) = @_;
    my ($sth, $utf8_encoded_json_text, $expires);
    my ($time) = time();

	my ($stafftype, $staffid) = check_session($admin, $ajax);
	my $authorized = $stafftype;
	my $board = undef;

	if (!$authorized) {
		$utf8_encoded_json_text = encode_json({
			"error_code" => 401,
			"error_msg" => 'Unauthorized'
		});
	} else {
		$comment = clean_string( decode_string( $comment, CHARSET ) );
		$icomment = clean_string( decode_string( $icomment, CHARSET ) );

		# set expiration date and add post link to ban
		if ($type eq 'ipban') {
			if ($sval1 =~ /\d+/) {
				$sval1 += $time;
				$expires = make_date($sval1, DATE_STYLE, S_WEEKDAYS, S_MONTHS);
			} else { $sval1 = ""; }

			$board = decode_string(BOARD_IDENT, CHARSET);

			if ($postid) {
				$comment .= ' (<!--reflink-->&gt;&gt;/' . $board . '/' . $postid . ')';
			}

			$board = undef if ($global and $stafftype == 1); # only admins can set global bans
		}

		# wordfilter string will be used in a regex and must be restricted to
		# prevent injection of perl code and long running or invalid expressions
		if ($type eq 'filter') {
			my $allowed = '^[a-zA-Z0-9äöüÄÖÜß|]{4,50}$';
			make_error(S_WRDFLTINVALID) if ($sval1 !~ /$allowed/ or encode_string($comment) !~ /$allowed/);
		}

		$sth = $dbh->prepare(
			"INSERT INTO " . SQL_ADMIN_TABLE . " VALUES(null,?,?,?,?,?,FROM_UNIXTIME(?),?,?,?);" )
		  or make_error(S_SQLFAIL);
		$sth->execute( $type, $comment, $ival1, $ival2, $sval1, $time, $board, $icomment, $staffid )
		  or make_error(S_SQLFAIL);

		if ($postid and $flag and !$delete) {
			$sth = $dbh->prepare( "UPDATE " . SQL_TABLE . " SET banned=? WHERE num=? LIMIT 1;" )
			  or make_error(S_SQLFAIL);
			$sth->execute($time, $postid) or make_error(S_SQLFAIL);
		}
		if ($postid and $delete) {
			delete_post($postid, "", 0, 0, $admin, $staffid);
		}

		add_log_entry("New " . $type, $staffid, $postid, $comment, $ival1);

		$utf8_encoded_json_text = encode_json({
			"error_code" => 200,
			"info_msg" => S_BANADDED,
			"banned_ip" => dec_to_dot($ival1),
			"banned_mask" => dec_to_dot($ival2),
			"expires" => $expires,
			"reason" => $comment,
			"postid" => $postid
		});
	}

	if ($ajax) {
		make_json_header();
		print $utf8_encoded_json_text;
	} else {
		make_http_forward(get_script_name() . "?task=bans&board=" . get_board_id());
	}
}

sub check_admin_entry {
    my ($admin, $ival1) = @_;
    my ($sth, $utf8_encoded_json_text, $results, $info_msg);

	my ($authorized) = check_session($admin, 1);

	if (!$authorized) {
		$utf8_encoded_json_text = encode_json({"error_code" => 401, "error_msg" => 'Unauthorized'});
	} else {
		if (!$ival1) {
			$utf8_encoded_json_text = encode_json({"error_code" => 500, "error_msg" => 'Invalid parameter'});
		} else {
			$sth = $dbh->prepare("SELECT count(*) FROM "
				. SQL_ADMIN_TABLE
				. " WHERE type='ipban' AND ival1=? AND (CAST(sval1 AS UNSIGNED)>? OR sval1='')"
				. " AND (boards IS NULL OR boards=?);");
			$sth->execute(dot_to_dec($ival1), time(), decode_string(BOARD_IDENT, CHARSET));
			$results = ($sth->fetchrow_array())[0];
			$info_msg = S_BANFOUND if ($results);

			$utf8_encoded_json_text = encode_json({
				"error_code" => 200, "info_msg" => $info_msg, "results" => $results
			});
		}
	}
    make_json_header();
    print $utf8_encoded_json_text;
}

sub remove_admin_entry {
    my ( $admin, $num ) = @_;
    my ($sth, $row);

	my ($stafftype, $staffid) = check_session($admin);

	# get old values for logging
    $sth = $dbh->prepare( "SELECT type,comment,ival1 FROM " . SQL_ADMIN_TABLE . " WHERE num=?;" )
      or make_error(S_SQLFAIL);
    $sth->execute($num) or make_error(S_SQLFAIL);
	$row = $sth->fetchrow_hashref();

	# remove entry
    $sth = $dbh->prepare( "DELETE FROM " . SQL_ADMIN_TABLE . " WHERE num=?;" )
      or make_error(S_SQLFAIL);
    $sth->execute($num) or make_error(S_SQLFAIL);

	add_log_entry("Remove " . $$row{type}, $staffid, 0, $$row{comment}, $$row{ival1});

    make_http_forward(get_script_name() . "?task=bans&board=" . get_board_id());
}

sub add_user {
	my ($admin, $user, $password1, $password2, $type) = @_;
	my ($sth);

	make_error(S_NOPRIV) unless (check_session($admin))[0] == 1;

	$user = clean_string(decode_string($user, CHARSET));

	if ($user and $password1) {
		make_error(S_PWCHANGEERR1) unless ($password1 eq $password2);
		$password1 = crypt_password($password1);
		$sth = $dbh->prepare("SELECT count(*) FROM " . SQL_STAFF_TABLE . " WHERE user=?;")
		  or make_error(S_SQLFAIL);
		$sth->execute($user) or make_error(S_SQLFAIL);
		make_error(S_ACCOUNTEXISTS) if (($sth->fetchrow_array())[0]);
		$sth = $dbh->prepare("INSERT INTO " . SQL_STAFF_TABLE
			. " VALUES(null,?,?,1,?,null,null,null,null);") or make_error(S_SQLFAIL);
		$sth->execute($user, $password1, $type) or make_error(S_SQLFAIL);
	}

	make_http_forward(get_script_name() . "?task=staff&board=" . get_board_id());
}

sub remove_user {
	my ($admin, $num) = @_;
	my ($sth);

	my ($stafftype, $staffid) = check_session($admin);
	make_error(S_NOPRIV) unless ($stafftype == 1);
	make_error(S_NOPRIV) unless ($staffid != $num);

	$sth = $dbh->prepare("DELETE FROM " . SQL_STAFF_TABLE . " WHERE num=? AND user<>'admin';")
	  or make_error(S_SQLFAIL);
	$sth->execute($num) or make_error(S_SQLFAIL);

	make_http_forward(get_script_name() . "?task=staff&board=" . get_board_id());
}

sub change_user {
	my ($admin, $num, $enable) = @_;
	my ($sth);

	my ($stafftype, $staffid) = check_session($admin);
	make_error(S_NOPRIV) unless ($stafftype == 1);
	make_error(S_NOPRIV) unless ($staffid != $num);

	$sth = $dbh->prepare("UPDATE " .  SQL_STAFF_TABLE . " SET enabled=? WHERE num=?;")
	  or make_error(S_SQLFAIL);
	$sth->execute($enable, $num) or make_error(S_SQLFAIL);

	make_http_forward(get_script_name() . "?task=staff&board=" . get_board_id());
}

sub change_user_password {
	my ($admin, $num, $oldpw, $newpw1, $newpw2) = @_;
	my ($sth, $msg, $row, $user, $pass, $pwreset);

	my ($stafftype, $staffid, $staffname) = check_session($admin);
	$num = $staffid unless ($num);

	# users can change their own password. admins can change any password.
	make_error(S_NOPRIV) unless ($staffid == $num or $stafftype == 1);

	$pwreset = ($staffid != $num);

	$sth = $dbh->prepare("SELECT user,password FROM " . SQL_STAFF_TABLE . " WHERE num=?;")
	  or make_error(S_SQLFAIL);
	$sth->execute($num) or make_error(S_SQLFAIL);
	$row = get_decoded_hashref($sth);
	$user = $$row{user};
	$pass = $$row{password};

	$msg = "";
	$oldpw = crypt_password($oldpw);

	if (($oldpw or $pwreset) and $newpw1 and $newpw2) {
		if ($newpw1 ne $newpw2) {
			$msg = S_PWCHANGEERR1 . " " . S_PWCHANGEFAIL;
		} else {
			if (!$pwreset and ($oldpw ne $pass)) {
				$msg = S_PWCHANGEERR2 . " " . S_PWCHANGEFAIL;
			} else {
				$newpw1 = crypt_password($newpw1);
				$sth = $dbh->prepare("UPDATE " . SQL_STAFF_TABLE . " SET password=? WHERE num=?;")
				  or make_error(S_SQLFAIL);
				$sth->execute($newpw1,$num) or make_error(S_SQLFAIL);
				$msg = sprintf(S_PWCHANGEOK, $user);
			}
		}
	}

	make_http_header();
	print encode_string(CHANGE_PASSWORD_TEMPLATE->(
		admin => $stafftype,
		staffname => $staffname,
		msg => $msg,
		num => $num,
		user => $user,
		pwreset => $pwreset
	));
}

sub delete_all {
    my ($admin, $ip, $mask, $go) = @_;
    my ($sth, $row, @posts);

	my ($stafftype, $staffid, $staffname) = check_session($admin);

	# TODO: merge SQL queries for post/thread counting and deleting into one section

	unless ($go and $ip) # do not allow empty IP (would delete anonymized (staff) posts)
	{
		my ($pcount, $tcount);

		if (length(pack('w', $ip)) > 5) { # IPv6 counting
			$pcount = 0;
			$tcount = 0;

			my $find_ip = new Net::IP(dec_to_dot($ip)) or make_error(Net::IP::Error());
			my $mask_len = get_mask_len($mask);
			my $find_bits = substr($find_ip->binip(), 0, $mask_len);

			# fetch all IPv6 post IDs and IPs from the database
			$sth = $dbh->prepare(
				"SELECT num,parent,ip FROM " . SQL_TABLE . " WHERE LENGTH(ip)>10 AND adminpost=0;"
			) or make_error(S_SQLFAIL);
			$sth->execute();

			while ($row = $sth->fetchrow_hashref()) {
				my $post_ip = new Net::IP(dec_to_dot($$row{ip})) or make_error(Net::IP::Error());

				# compare binary strings of $find_ip and $post_ip up to mask length
				my $post_bits = substr($post_ip->binip(), 0, $mask_len);
				if ($find_bits eq $post_bits) {
					$pcount++;
					$tcount++ unless ($$row{parent});
				}
			}
		} else { # IPv4 counting
			$sth = $dbh->prepare(
				"SELECT count(*) FROM " . SQL_TABLE . " WHERE ip & ? = ? & ? AND adminpost=0;"
			) or make_error(S_SQLFAIL);
			$sth->execute($mask, $ip, $mask) or make_error(S_SQLFAIL);
			$pcount = ($sth->fetchrow_array())[0];

			$sth = $dbh->prepare(
				"SELECT count(*) FROM " . SQL_TABLE . " WHERE ip & ? = ? & ? AND parent=0 AND adminpost=0;"
			) or make_error(S_SQLFAIL);
			$sth->execute($mask, $ip, $mask) or make_error(S_SQLFAIL);
			$tcount = ($sth->fetchrow_array())[0];
		}

		make_http_header();
		print encode_string(DELETE_PANEL_TEMPLATE->(
			admin   => $stafftype,
			staffname => $staffname,
			ip      => $ip,
			mask    => $mask,
			posts   => $pcount,
			threads => $tcount
		));
	}
	else
	{
		if (length(pack('w', $ip)) > 5) { # IPv6 deletions
			my $find_ip = new Net::IP(dec_to_dot($ip)) or make_error(Net::IP::Error());
			my $mask_len = get_mask_len($mask);
			my $find_bits = substr($find_ip->binip(), 0, $mask_len);

			# fetch all IPv6 post IDs and IPs from the database
			$sth = $dbh->prepare(
				"SELECT num,parent,ip FROM " . SQL_TABLE . " WHERE LENGTH(ip)>10 AND adminpost=0;"
			) or make_error(S_SQLFAIL);
			$sth->execute();

			while ($row = $sth->fetchrow_hashref()) {
				my $post_ip = new Net::IP(dec_to_dot($$row{ip})) or make_error(Net::IP::Error());

				# compare binary strings of $find_ip and $post_ip up to mask length
				my $post_bits = substr($post_ip->binip(), 0, $mask_len);
				if ($find_bits eq $post_bits) {
					push (@posts, $$row{num});
				}
			}
		} else { # IPv4 deletions
			$sth =
			  $dbh->prepare( "SELECT num FROM " . SQL_TABLE . " WHERE ip & ? = ? & ? AND adminpost=0;" )
			  or make_error(S_SQLFAIL);
			$sth->execute( $mask, $ip, $mask ) or make_error(S_SQLFAIL);
			while ( $row = $sth->fetchrow_hashref() ) { push( @posts, $$row{num} ); }
		}
		delete_stuff('', 0, $admin, 0, @posts);
	}
}

sub get_boards {
	my $boards;
	my @files = glob '*'; # get all files in webroot
	foreach my $item (@files) {
		# check for directories and if they contain a config.pl
		if (-d $item and -f $item . "/config.pl") {
			$boards .= ' /<a href="' . get_script_name() . '?board=' . urlenc($item) . '">'
			  . decode_string($item, CHARSET) . '</a>/ ';
		}
	}
	return $boards;
}

sub check_password {
    my ( $admin, $password ) = @_;

	# temporary hack - TODO: replace check_password() by check_session($session)
	return if (check_session($admin));

    make_error(S_WRONGPASS);
}

sub check_session {
	my ($session, $noerror, $level) = @_;
	my ($sth, $row);

	my $numip = dot_to_dec(get_remote_addr());
	$session = clean_string($session);

	if ($session) {
		$sth = $dbh->prepare("SELECT * FROM " . SQL_STAFF_TABLE . " WHERE session=?;")
		  or make_error(S_SQLFAIL);
		$sth->execute($session) or make_error(S_SQLFAIL);

		if ($row = $sth->fetchrow_hashref()) {
			if ($$row{enabled} and $$row{session} eq $session and $$row{ip} eq $numip) {
				# update session activity once every hour
				if ($$row{timestamp} + 60 * 60 < time()) {
					$sth = $dbh->prepare("UPDATE " . SQL_STAFF_TABLE . " SET timestamp=? WHERE num=?;")
					  or make_error(S_SQLFAIL);
					$sth->execute(time(), $$row{num}) or make_error(S_SQLFAIL);
				}
				# check privilege level
				#make_error(S_NOPRIV) if ($level and $level > $$row{type});
				# return staff id num as second parameter
				return ($$row{type}, $$row{num}, $$row{user});
			}
		}
	}

	make_error(S_BADSESSION) unless $noerror;
	return 0;
}

sub crypt_password {
    my $crypt = hide_data((shift), 18, "admin", SECRET, 1);
    $crypt =~ tr/+/./;    # for web shit
    return $crypt;
}

#
# Page creation utils
#

sub make_http_header {
	my ($not_found) = @_;
	print $query->header(-type=>'text/html', -status=>'404 Not found', -charset=>CHARSET) if ($not_found);
	print $query->header(-type=>'text/html', -charset=>CHARSET) if (!$not_found);
}

sub make_json_header {
	print "Cache-Control: no-cache, no-store, must-revalidate\n";
	print "Expires: Mon, 12 Apr 2010 05:00:00 GMT\n";
	print "Content-Type: application/json\n";
	print "Access-Control-Allow-Origin: *\n";
	print "\n";
}

sub make_error {
    my ($error, $not_found) = @_;

    make_http_header() if (!defined $not_found);
    make_http_header($not_found) if (defined $not_found);

    print encode_string(
        ERROR_TEMPLATE->(
            error          => $error,
            error_page     => S_ERRORTITLE,
            error_title    => S_ERRORTITLE
        )
    );

    if ($dbh) {
        $dbh->{Warn} = 0;
        $dbh->disconnect();
    }

    if (ERRORLOG)    # could print even more data, really.
    {
        open ERRORFILE, '>>' . ERRORLOG;
        print ERRORFILE $error . "\n";
        print ERRORFILE $ENV{HTTP_USER_AGENT} . "\n";
        print ERRORFILE "**\n";
        close ERRORFILE;
    }

    # delete temp files

    exit;
}

sub make_ban {
    my ($title, @bans) = @_;

    make_http_header();
    print encode_string(
        ERROR_TEMPLATE->(
            bans           => \@bans,
            error_page     => $title,
            error_title    => $title,
            banned         => 1
        )
    );
    if ($dbh) {
        $dbh->{Warn} = 0;
        $dbh->disconnect();
    }
    exit;
}

sub get_board_id {
	return urlenc(encode_string(BOARD_IDENT));
}

sub get_script_name {
    #return decode_string($ENV{SCRIPT_NAME}, CHARSET); # this would have to be done in many places to support non-ASCII paths
    return $ENV{SCRIPT_NAME};
}

sub get_secure_script_name {
    return 'https://' . $ENV{SERVER_NAME} . $ENV{SCRIPT_NAME}
      if (USE_SECURE_ADMIN);
    return $ENV{SCRIPT_NAME};
}

sub expand_filename {
    my ($filename, $board) = @_;

    return $filename if ( $filename =~ m!^/! );
    return $filename if ( $filename =~ m!^\w+:! );

    my ($self_path) = $ENV{SCRIPT_NAME} =~ m!^(.*/)[^/]+$!;
    $board = get_board_id() unless ($board);
    #return decode_string($self_path, CHARSET) . $filename;
    return $self_path . $board . '/' . $filename;
}

sub expand_image_filename { # TODO: remove and replace by expand_filename since load balancing is not used anymore
    my $filename = shift;

    return expand_filename(clean_path($filename));

    #my ($self_path) = $ENV{SCRIPT_NAME} =~ m!^(.*/)[^/]+$!;
    #my $src = IMG_DIR;
    #$filename =~ /$src(.*)/;
    #return $self_path . REDIR_DIR . clean_path($1) . '.html';
}

sub get_reply_link {
	my ($reply, $parent, $board) = @_;

	return expand_filename("thread/" . $parent, $board) . '#' . $reply if ($parent);
	return expand_filename("thread/" . $reply, $board);
}

sub get_page_count {
    my ($total, $isAdmin) = @_;
    if (!$isAdmin and $total > MAX_SHOWN_THREADS) {
        $total = MAX_SHOWN_THREADS;
    }
    return int(($total + IMAGES_PER_PAGE - 1) / IMAGES_PER_PAGE);
}

sub get_filetypes_hash {
    my %filetypes = FILETYPES;
    $filetypes{gif} = $filetypes{jpg} = $filetypes{jpeg} = $filetypes{png} = 'image';
	$filetypes{pdf} = 'doc';
	$filetypes{webm} = $filetypes{mp4} = 'video';
	return %filetypes;
}

sub get_filetypes {
	my %filetypes = get_filetypes_hash();
    return join ", ", map { uc } sort keys %filetypes;
}

sub get_filetypes_table {
	my %filetypes = get_filetypes_hash();
	my %filegroups = FILEGROUPS;
	my %filesizes = FILESIZES;
	my @groups = split(' ', GROUPORDER);
	my @rows;
	my $blocks = 0;
	my $output = '<table style="margin:0px;border-collapse:collapse;display:inline-table;">'
		. "\n<tr>\n\t" . '<td colspan="4">'
		. sprintf(S_ALLOWED, get_displaysize(MAX_KB*1024, DECIMAL_MARK, 0)) . "</td>\n</tr><tr>\n";
	delete $filetypes{'jpeg'}; # show only jpg

	foreach my $group (@groups) {
		my @extensions;
		foreach my $ext (keys %filetypes) {
			if ($filetypes{$ext} eq $group or $group eq 'other') {
				my $ext_desc = uc($ext);
				$ext_desc .= ' (' . get_displaysize($filesizes{$ext}*1024, DECIMAL_MARK, 0) . ')' if ($filesizes{$ext});
				push(@extensions, $ext_desc);
				delete $filetypes{$ext};
			}
		}
		if (@extensions) {
			$output .= "\t<td><strong>" . $filegroups{$group} . ":</strong>&nbsp;</td>\n\t<td>"
				. join(", ", sort(@extensions)) . "&nbsp;&nbsp;</td>\n";
			$blocks++;
			if (!($blocks % 2)) {
				push(@rows, $output);
				$output = '';
				$blocks = 0;
			}
		}
	}
	push(@rows, $output) if ($output);
	return join("</tr><tr>\n", @rows) . "</tr>\n</table>";
}

#sub dot_to_dec($)
#{
#	return unpack('N',pack('C4',split(/\./, $_[0]))); # wow, magic.
#}

#sub dec_to_dot($)
#{
#	return join('.',unpack('C4',pack('N',$_[0])));
#}

sub parse_range {
    my ( $ip, $mask ) = @_;

	if ($ip =~ /:/ or length(pack('w', $ip)) > 5) # IPv6
	{
		if ($mask =~ /:/) {
			$mask = dot_to_dec($mask);

			# verify that $mask is a valid IPv6 mask
			my $binmask = $mask->as_bin();
			my $binlen = length($binmask); # must be 130
			my $maskok = $binmask =~ /^0b1+0*$/;
			make_error(S_IPMASKINVALID) unless ($binlen == 130 and $maskok);
		}
		else { $mask = "340282366920938463463374607431768211455"; }
	}
	else # IPv4
	{
		if ( $mask =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
			$mask = dot_to_dec($mask);

			# verfiy that $mask is a valid IPv4 mask
			my $binmask = sprintf("%b", $mask);
			my $binlen = length($binmask); # must be 32
			my $maskok = $binmask =~ /^1+0*$/;
			make_error(S_IPMASKINVALID) unless ($binlen == 32 and $maskok);
		}
		elsif ( $mask =~ /(\d+)/ ) { $mask = ( ~( ( 1 << $1 ) - 1 ) ); }
		else                       { $mask = 0xffffffff; }
	}

	# convert IPv4 and IPv6 addresses to numeric string
    $ip = dot_to_dec($ip) if ( $ip =~ /(^\d+\.\d+\.\d+\.\d+$)|:/ );

    return ( $ip, $mask );
}

sub get_remote_addr {
	my $ip;

	$ip = $ENV{HTTP_X_REAL_IP};
	$ip = $ENV{REMOTE_ADDR} if (!defined($ip));

	return $ip;
}

#
# Database utils
#

sub init_database {
    my ($sth);

    $sth = $dbh->do( "DROP TABLE " . SQL_TABLE . ";" )
      if ( table_exists(SQL_TABLE) );
    $sth = $dbh->prepare(
		"CREATE TABLE " . SQL_TABLE . " (" .

		"num " . get_sql_autoincrement() . "," . # Post number, auto-increments
		"parent INTEGER," .     # Parent post for replies in threads. For original posts, must be
		                        # set to 0 (and not null)
		"timestamp INTEGER," .  # Timestamp in seconds for when the post was created
		"lasthit INTEGER," .    # Last activity in the thread. Must be set to the same value for
		                        # BOTH the original post and all replies!

		"ip TEXT," .            # IP number of poster, in integer form! Stored as text because IPv6
		                        # 128 bit integers are not always supported.
		"name TEXT," .          # Name of the poster
		"trip TEXT," .          # Tripcode (encoded)
		"email TEXT," .         # Email address
		"subject TEXT," .       # Subject
		"password TEXT," .      # Deletion password (in plaintext)
		"comment TEXT," .       # Comment text, HTML encoded.

		"banned INTEGER," .     # Timestamp when the post was banned
		"autosage INTEGER," .   # Flag to indicate that thread is on bump limit
		"adminpost INTEGER," .  # Post was made by a staff member
		"locked INTEGER," .     # Thread is locked (applied to parent post only)
		"sticky INTEGER," .     # Thread is sticky (applied to all posts of a thread)
		"location TEXT," .      # Geo::IP information for the IP address if available
		"secure TEXT" .         # Cipher information if posted using encrypted connection

		");"
    ) or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

	$sth = $dbh->prepare(
		"CREATE INDEX parent ON " . SQL_TABLE . " (parent);"
    ) or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);
}

sub init_files_database {
    my ($sth);

    $sth = $dbh->do( "DROP TABLE " . SQL_TABLE_IMG . ";" )
      if ( table_exists(SQL_TABLE_IMG) );
    $sth = $dbh->prepare(
		"CREATE TABLE " . SQL_TABLE_IMG . " (" .

		"num " . get_sql_autoincrement() . "," . # Primary key
		"thread INTEGER," .    # Thread ID / parent (num in comments table) of file's post
		                       # Reduces queries needed for thread output and thread deletion
		"post INTEGER," .      # Post ID (num in comments table) where file belongs to
		"image TEXT," .        # Image filename with path and extension (IE, src/1081231233721.jpg)
		"size INTEGER," .      # File size in bytes
		"md5 TEXT," .          # md5 sum in hex
		"width INTEGER," .     # Width of image in pixels
		"height INTEGER," .    # Height of image in pixels
		"thumbnail TEXT," .    # Thumbnail filename with path and extension
		"tn_width INTEGER," .  # Thumbnail width in pixels
		"tn_height INTEGER," . # Thumbnail height in pixels
		"uploadname TEXT," .   # Original filename supplied by the user agent
		"info TEXT," .         # Short file information displayed in the post
		"info_all TEXT" .      # Full file information displayed in the tooltip

		");"
    ) or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

	$sth = $dbh->prepare(
		"CREATE INDEX thread ON " . SQL_TABLE_IMG . " (thread);"
    ) or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

	$sth = $dbh->prepare(
		"CREATE INDEX post ON " . SQL_TABLE_IMG . " (post);"
    ) or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

	# temporary flag to indicate that all sql tables have been created.
	# will be replaced by board management code.
	open(DONE, ">" . BOARD_IDENT . "/sql_created") or make_error(S_NOTWRITE);
	print DONE "1";
	close DONE;
}

sub init_admin_database {
    my ($sth);

    $sth = $dbh->do( "DROP TABLE " . SQL_ADMIN_TABLE . ";" )
      if ( table_exists(SQL_ADMIN_TABLE) );
    $sth = $dbh->prepare(
            "CREATE TABLE "
          . SQL_ADMIN_TABLE . " ("
          .

          "num "
          . get_sql_autoincrement() . ","
          .                    # Entry number, auto-increments
          "type TEXT," .       # Type of entry (ipban, wordban, etc)
          "comment TEXT," .    # Comment for the entry (ipban: public ban reason)
          "ival1 TEXT," .      # Integer value 1 (usually IP)
          "ival2 TEXT," .      # Integer value 2 (usually netmask)
          "sval1 TEXT," .      # String value 1 (ipban: expiration timestamp)
          "date TEXT," .       # Human-readable form of date
          "boards TEXT," .     # Board for 'ipban' - currently only one board or all boards (null)
          "icomment TEXT," .   # Internal staff comment
          "staff INTEGER" .    # Staff account num from SQL_STAFF_TABLE

          ");"
    ) or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);
}

sub init_staff_database() {
	my ($sth);

	$sth=$dbh->do("DROP TABLE " . SQL_STAFF_TABLE . ";") if (table_exists(SQL_STAFF_TABLE));
	$sth=$dbh->prepare("CREATE TABLE " . SQL_STAFF_TABLE . " (".

	"num ".get_sql_autoincrement().",".	# Entry number, auto-increments
	"user TEXT,".				# Login name
	"password TEXT,".			# Password (crypted)
	"enabled INTEGER,".			# Accound enabled or disabled
	"type INTEGER,".			# Access level: 1=Admin and 2=Mod
	"boards TEXT, ".			# Comma separated list of assigned boards. Empty = all boards.
	"session TEXT,".			# Random string, associated after successful login
	"ip TEXT,".					# IP from which the session was created
	"timestamp INTEGER".		# Last activity of the sesssion. Old sessions are removed.

	");") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	# add initial admin entry. password is from site_config.
	$sth = $dbh->prepare("INSERT INTO " . SQL_STAFF_TABLE . " VALUES(null,'admin',?,1,1,null,null,null,null);")
	  or make_error(S_SQLFAIL);
	$sth->execute(crypt_password(ADMIN_PASS)) or make_error(S_SQLFAIL);
}

sub init_staff_log_database() {
	my ($sth);

	$sth=$dbh->do("DROP TABLE " . SQL_STAFF_LOG_TABLE . ";") if (table_exists(SQL_STAFF_LOG_TABLE));
	$sth=$dbh->prepare("CREATE TABLE ". SQL_STAFF_LOG_TABLE . " (".

	"timestamp INTEGER," .		# Unix time when action was executed
	"event TEXT," .				# Descriptive text constant of the event
	"board TEXT," .				# Board where the action was performed
	"post INTEGER," .			# Post or thread num from comments table
	"staff INTEGER," .			# Staff account num from SQL_STAFF_TABLE
	"ip TEXT," .				# IP of the post in case of ban or deletion
	"comment TEXT" .			# Original post comment in case of deletion or edit

	");") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
}

sub repair_database {
    my ( $sth, $row, @threads, $thread );

    $sth = $dbh->prepare( "SELECT * FROM " . SQL_TABLE . " WHERE parent=0;" )
      or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

    while ( $row = $sth->fetchrow_hashref() ) { push( @threads, $row ); }

    foreach $thread (@threads) {

        # fix lasthit
        my ($upd);

        $upd = $dbh->prepare(
            "UPDATE " . SQL_TABLE . " SET lasthit=? WHERE parent=?;" )
          or make_error(S_SQLFAIL);
        $upd->execute( $$thread{lasthit}, $$thread{num} )
          or make_error( S_SQLFAIL . " " . $dbh->errstr() );
    }
}

sub get_sql_autoincrement {
    return 'INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT'
      if ( SQL_DBI_SOURCE =~ /^DBI:mysql:/i );
    return 'INTEGER PRIMARY KEY' if ( SQL_DBI_SOURCE =~ /^DBI:SQLite:/i );
    return 'INTEGER PRIMARY KEY' if ( SQL_DBI_SOURCE =~ /^DBI:SQLite2:/i );

    make_error(S_SQLCONF);  # maybe there should be a sane default case instead?
}

sub get_sql_lastinsertid()
{
	return 'LAST_INSERT_ID()' if(SQL_DBI_SOURCE=~/^DBI:mysql:/i);
	return 'last_insert_rowid()' if(SQL_DBI_SOURCE=~/^DBI:SQLite:/i);
	return 'last_insert_rowid()' if(SQL_DBI_SOURCE=~/^DBI:SQLite2:/i);

	make_error(S_SQLCONF);
}

sub trim_database {
    my ( $sth, $row, $order );

    if   ( TRIM_METHOD == 0 ) { $order = 'num ASC'; }
    else                      { $order = 'lasthit ASC'; }

    if (MAX_AGE)            # needs testing
    {
        my $mintime = time() - (MAX_AGE) * 3600;

        $sth =
          $dbh->prepare( "SELECT * FROM "
              . SQL_TABLE
              . " WHERE parent=0 AND timestamp<=$mintime AND sticky IS NULL;"
          ) or make_error(S_SQLFAIL);
        $sth->execute() or make_error(S_SQLFAIL);

        while ( $row = $sth->fetchrow_hashref() ) {
            delete_post( $$row{num}, "", 0, 0 );
        }
    }

    my $threads = count_threads();
    my ( $posts, $size ) = count_posts();
    my $max_threads = ( MAX_THREADS                 or $threads );
    my $max_posts   = ( MAX_POSTS                   or $posts );
    my $max_size    = ( MAX_MEGABYTES * 1024 * 1024 or $size );

    while ($threads > $max_threads
        or $posts > $max_posts
        or $size > $max_size )
    {
        $sth =
          $dbh->prepare( "SELECT * FROM "
              . SQL_TABLE
              . " WHERE parent=0 AND sticky IS NULL ORDER BY $order LIMIT 1;"
          ) or make_error(S_SQLFAIL);
        $sth->execute() or make_error(S_SQLFAIL);

        if ( $row = $sth->fetchrow_hashref() ) {
            my ( $threadposts, $threadsize ) = count_posts( $$row{num} );

            delete_post( $$row{num}, "", 0, 0 );

            $threads--;
            $posts -= $threadposts;
            $size  -= $threadsize;
        }
        else { last; }    # shouldn't happen
    }
}

sub table_exists {
    my ($table) = @_;
    my ($sth);

    return 0
      unless ( $sth =
        $dbh->prepare( "SELECT * FROM " . $table . " LIMIT 1;" ) );
    return 0 unless ( $sth->execute() );
    return 1;
}

sub count_threads {
    my ($sth);

    $sth =
      $dbh->prepare( "SELECT count(*) FROM " . SQL_TABLE . " WHERE parent=0;" )
      or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);

    return ( $sth->fetchrow_array() )[0];
}

sub count_posts {
    my ($parent) = @_;
    my ($sth, $where, $count, $size);

    $where = "WHERE parent=$parent or num=$parent" if ($parent);
    $sth = $dbh->prepare(
        "SELECT count(*) FROM " . SQL_TABLE . " $where;" )
      or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);
	$count = ($sth->fetchrow_array())[0];

    $where = "WHERE thread=$parent" if ($parent);
    $sth = $dbh->prepare(
        "SELECT sum(size) FROM " . SQL_TABLE_IMG . " $where;" )
      or make_error(S_SQLFAIL);
    $sth->execute() or make_error(S_SQLFAIL);
	$size = ($sth->fetchrow_array())[0];

    return ($count, $size);
}

sub thread_exists {
    my ($thread) = @_;
    my ($sth);

    $sth = $dbh->prepare(
        "SELECT count(*) FROM " . SQL_TABLE . " WHERE num=? AND parent=0;" )
      or make_error(S_SQLFAIL);
    $sth->execute($thread) or make_error(S_SQLFAIL);

    return ( $sth->fetchrow_array() )[0];
}

sub get_decoded_hashref {
    my ($sth) = @_;

    my $row = $sth->fetchrow_hashref();

    if ( $row and $has_encode ) {
        for my $k (
            keys %$row
          )    # don't blame me for this shit, I got this from perlunicode.
        {
            defined && /[^\000-\177]/ && Encode::_utf8_on($_) for $row->{$k};
        }

#        if ( SQL_DBI_SOURCE =~ /^DBI:mysql:/i )    # OMGWTFBBQ
#        {
#            for my $k ( keys %$row ) {
#                $$row{$k} =~ s/chr\(([0-9]+)\)/chr($1)/ge if defined;
#            }
#        }
    }

    return $row;
}

sub get_decoded_arrayref {
    my ($sth) = @_;

    my $row = $sth->fetchrow_arrayref();

    if ( $row and $has_encode ) {

        # don't blame me for this shit, I got this from perlunicode.
        defined && /[^\000-\177]/ && Encode::_utf8_on($_) for @$row;

#        if ( SQL_DBI_SOURCE =~ /^DBI:mysql:/i )    # OMGWTFBBQ
#        {
#            s/chr\(([0-9]+)\)/chr($1)/ge for @$row;
#        }
    }

    return $row;
}

sub debug_exec_time {
	my ($label, $done) = @_;
	return unless ($has_timer);

	my $lap = Time::HiRes::gettimeofday();
	$has_timer_output .= sprintf("%.0f ms (%s) ", ($lap - $has_timer) * 1000, $label);
	$has_timer_output .= "+ " unless ($done);

	if ($done) {
		$has_timer_output .= sprintf("= %.0f ms (total)", ($lap - $has_timer_start) * 1000);
		my $result = '<div class="omittedposts">' . $has_timer_output . "</div>\n";
		return $result;
	}
	$has_timer = Time::HiRes::gettimeofday(); # lap reset timer
}

sub update_db_schema3 {
	# add three new columns to admin table
	$sth = $dbh->prepare("SHOW COLUMNS FROM " . SQL_ADMIN_TABLE . " WHERE field = 'staff';");
	if ($sth->execute()) {
		unless (($sth->fetchrow_array())[0]) {
			$sth = $dbh->prepare(
				"ALTER TABLE " . SQL_ADMIN_TABLE . " ADD boards TEXT, ADD icomment TEXT, ADD staff INTEGER;"
			) or make_error($dbh->errstr);
			$sth->execute() or make_error($dbh->errstr);
		}
	}
	# check and change adminpost column of comments table
	$sth = $dbh->prepare("SHOW COLUMNS FROM " . SQL_TABLE . " WHERE field = 'adminpost';");
	if ($sth->execute()) {
		if (my $row = $sth->fetchrow_hashref()) {
			if ($$row{Type} eq 'tinyint(1)') {
				$sth = $dbh->prepare(
					"ALTER TABLE " . SQL_TABLE . " CHANGE adminpost adminpost INTEGER;"
				) or make_error($dbh->errstr);
				$sth->execute() or make_error($dbh->errstr);
			} else {
				$sth->finish;
			}
		}
	}
}

sub update_db_schema2 {  # mysql-specific. will be removed after migration is done.
	$sth = $dbh->prepare("SHOW COLUMNS FROM " . SQL_TABLE . " WHERE field = 'location';");
	if ($sth->execute()) {
		if (my $row = $sth->fetchrow_hashref()) {
			if ($$row{Type} eq 'varchar(25)') {
				$sth = $dbh->prepare(
					"ALTER TABLE " . SQL_TABLE . " CHANGE location location TEXT;"
				) or make_error($dbh->errstr);
				$sth->execute() or make_error($dbh->errstr);
			} else {
				$sth->finish;
			}
		}
	}
}

sub update_files_meta {
	my ($row, $sth2, $info, $info_all);

    return unless ($sth = $dbh->prepare("SELECT 1 FROM " . SQL_TABLE_IMG . " WHERE info_all IS NOT NULL LIMIT 1;"));
	return unless ($sth->execute()); # exit if schema was not yet updated
	if (($sth->fetchrow_array())[0]) { # at least one info_all field was filled. update already done, exit.
		$sth->finish;
		return;
	}

    $sth = $dbh->prepare(
		"SELECT num, image FROM " . SQL_TABLE_IMG . " WHERE image IS NOT NULL AND size>0 AND info_all IS NULL;"
	) or make_error($dbh->errstr);
    $sth->execute() or make_error($dbh->errstr);

	$sth2 = $dbh->prepare(
		"UPDATE " . SQL_TABLE_IMG . " SET info=?, info_all=? WHERE num=?;"
	) or make_error($dbh->errstr);
    while ($row = $sth->fetchrow_hashref()) {
		$$row{image} =~ s!.*/!!;
		$$row{image} = BOARD_IDENT . '/' . IMG_DIR . $$row{image};
		if (-e $$row{image}) {
			($info, $info_all) = get_meta_markup($$row{image}, CHARSET, TOOLTIP_TAGS);
		} else {
			undef($info);
			$info_all = "File not found";
		}
		$sth2->execute($info, $info_all, $$row{num}) or make_error($dbh->errstr);
	}
}
