use strict;

BEGIN { require "wakautils.pl"; }
BEGIN { require "post_view.pl"; }

use constant NETMASK_SELECT_INCLUDE => q{
<select id="netmask" name="mask">
  <option value="255.0.0.0">/8 (IPv4 Class A)</option>
  <option value="255.255.0.0">/16 (IPv4 Class B)</option>
  <option value="255.255.255.0">/24 (IPv4 Class C)</option>
  <option value="255.255.255.255" selected="selected">/32 (IPv4 Host)</option>
  <option disabled>&#9472;&#9472;&#9472;&#9472;&#9472;&#9472;&#9472;&#9472;&#9472;&#9472;&#9472;&#9472;</option>
  <option value="ffff:ffff:ffff:0000:0000:0000:0000:0000">/48 (IPv6)</option>
  <option value="ffff:ffff:ffff:ff00:0000:0000:0000:0000">/56 (IPv6)</option>
  <option value="ffff:ffff:ffff:ffff:0000:0000:0000:0000">/64 (IPv6)</option>
  <option value="ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff">/128 (IPv6 Host)</option>
</select>
};

use constant DURATION_SELECT_INCLUDE => q{
<select id="duration" name="string">
	<option value="18000">5 Stunden</option>
	<option value="86400" selected="selected">1 Tag</option>
	<option value="259200">3 Tage</option>
	<option value="432000">5 Tage</option>
	<option value="604800">1 Woche</option>
	<option value="2419200">4 Wochen</option>
	<option value="">Permanent</option>
</select>
};

use constant NORMAL_HEAD_INCLUDE => q{

<!DOCTYPE html>
<html lang="<const BOARD_LANG>">
<head>
<meta charset="<const CHARSET>" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title><if $title><var $title></if><if !$title>/<const BOARD_IDENT>/ - <const BOARD_NAME></if></title>

<link rel="stylesheet" type="text/css" href="/static/css/phutaba.css" />
<if STYLESHEET><link rel="stylesheet" type="text/css" href="<const STYLESHEET>" /></if>
<if test_afmod()><link rel="stylesheet" type="text/css" href="/static/css/af.css" /></if>
<link rel="shortcut icon" type="image/x-icon" href="/img/favicon.ico" />
<link rel="icon" type="image/x-icon" href="/img/favicon.ico" />
<link rel="apple-touch-icon-precomposed" href="/img/favicon-152.png" />
<meta name="msapplication-TileImage" content="/img/favicon-144.png" />
<meta name="msapplication-TileColor" content="#ECE9E2" />
<meta name="msapplication-navbutton-color" content="#BFB5A1" />
<meta name="msapplication-config" content="none" />
<if TITLE && !$thread>
<meta name="application-name" content="<const TITLE> /<const BOARD_IDENT>/" />
<meta name="apple-mobile-web-app-title" content="<const TITLE>" />
</if>

<if $admin>
	<link rel="stylesheet" type="text/css" href="/static/vendor/jquery-ui.min.css" />
</if>

<style type="text/css">
<const ADDITIONAL_CSS>
</style>
</head>

<body>

<if $admin>
<div id="modpanel" class="hidden">
<table>
<tr>
	<td><b><const S_BANIPLABEL></b></td><td><input id="ip" type="text" name="ip" size="40" /></td>
</tr>
<tr><td><b><const S_BANMASKLABEL></b></td><td>
} . NETMASK_SELECT_INCLUDE . q{
</td></tr>
<tr><td><b><const S_BANDURATION></b></td><td>
} . DURATION_SELECT_INCLUDE . q{
</td></tr>
<if $admin eq 1>
<tr>
	<td><b><const S_BOARD></b></td><td>
		<label><input id="global1" name="global" value="0" type="radio" />/<const BOARD_IDENT>/</label>
		<label><input id="global2" name="global" value="1" checked="checked" type="radio" /><const S_BANGLOBAL></label>
	</td>
</tr>
</if>
<tr>
	<td><b><const S_BANREASONLABEL></b></td><td><input id="reason" type="text" name="reason" size="40" /></td>
</tr>
<tr>
	<td><b><const S_BANINTERNALCOMMENTLABEL></b></td><td><input id="icomment" type="text" name="icomment" size="40" /></td>
</tr>
<tr>
	<td colspan="2">
	<label><input id="ban_flag" type="checkbox" name="ban_flag" value="1" checked="checked" /> <b><const S_BANFLAGPOST></b></label>
	</td>
</tr>
<tr>
	<td colspan="2">
	<label><input id="del_post" type="checkbox" name="del_post" value="1" /> <b><const S_BANDELPOST></b></label>
	</td>
</tr>
</table>
<div id="infobox" style="display: none">
	<br />
	<b><const S_BANIPLABEL></b>: <span id="r_ip"></span><br />
	<b><const S_BANMASKLABEL></b>: <span id="r_mask"></span><br />
	<b>Ende</b>: <span id="r_expires"></span><br />
	<b><const S_BANREASONLABEL></b>: <span id="r_reason"></span><br />
	<b>Post-Nr.</b>: <span id="r_post"></span><br />
</div>
<p id="info" style="display: none"><span style="font-weight: bolder; color: #002233;">Info: <span style="font-weight: bolder" id="infodetails"></span></span></p>
<p id="error" style="display: none"><span style="font-weight: bolder; color: #FF0000;">Error: <span style="font-weight: bolder" id="errordetails"></span></span></p>
</div>
</if>

<div class="content">

<nav>
	<ul class="menu">
} . include("tpl/nav_boards.html") . q{
	</ul>

	<ul class="menu right">
} . include("tpl/nav_pages." . BOARD_LANG . ".html") . q{
	</ul>
</nav>

<header>
	<div class="header">
		<div class="banner">
			<a href="/<const BOARD_IDENT>/">
				<img src="/banner.pl?board=<var get_board_id()>" alt="Banner" />
			</a>
		</div>
		<div class="boardname" <if BOARD_DESC>style="margin-bottom: 5px;"</if>>/<const BOARD_IDENT>/ &ndash; <const BOARD_NAME></div>
		<if BOARD_DESC><div class="slogan">&bdquo;<const BOARD_DESC>&ldquo;</div></if>
	</div>
</header>

<if $postform or $locked or $admin><hr /></if>

};


use constant MANAGER_HEAD_INCLUDE => NORMAL_HEAD_INCLUDE . q{

<if $admin>
	<!--[<a href="<var expand_filename(HTML_SELF)>"><const S_MANARET></a>]-->
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=show"><const S_MANAPANEL></a>]
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=bans"><const S_MANABANS></a>]
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=log"><const S_MANALOG></a>]
	<if $admin eq 1>
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=mpanel"><const S_MANATOOLS></a>]
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=orphans"><const S_MANAORPH></a>]
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=staff"><const S_MANASTAFF></a>]
	</if>
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=changepass"><const S_MANAPASS></a>]
	[<a href="<var $self>?board=<var get_board_id()>&amp;task=logout"><var sprintf S_MANALOGOUT, $staffname></a>]
	[<var get_boards()>]
	<div class="passvalid"><const S_MANAMODE></div>
</if>
};


use constant NORMAL_FOOT_INCLUDE => q{

<footer>
	<p>Powered by <img src="/img/phutaba_icon.png" alt="" /> <strong>Phutaba</strong>.</p>
	<if ABUSE_EMAIL><p><em>Report illegal material to <a href="mailto:<const ABUSE_EMAIL>"><const ABUSE_EMAIL></a>.</em></p></if>
</footer>
<nav>
	<ul class="menu_bottom">
} . include("tpl/nav_boards.html") . q{
	</ul>
</nav>
</div>
<const TRACKING_CODE>

<script type="text/javascript" src="/static/vendor/wz_tooltip.js"></script>
<script type="text/javascript" src="/static/js/wakaba3.js"></script>
<script type="text/javascript" src="/static/vendor/jquery-1.11.3.min.js"></script>
<script type="text/javascript" src="/static/vendor/jquery.blockUI.js"></script>

<if $admin>
        <script type="text/javascript" src="/static/vendor/jquery-ui.min.js"></script>
        <script type="text/javascript" src="/static/js/admin.js"></script>
</if>

<if ENABLE_HIDE_THREADS && !$thread>
<script type="text/javascript" src="/static/vendor/jquery.cookie.js"></script>
<script type="text/javascript" src="/static/js/hidethreads.js"></script>
</if>

<script type="text/javascript">
/* <![CDATA[ */
  <if $postform>set_inputs("postform");</if>
  set_delpass("delform");

  var board = '<const BOARD_IDENT>';
  var thread_id = <if $thread><var $thread></if><if !$thread>null</if>;
  var filetypes = '<var get_filetypes()>';
  var msg_remove_file = '<const S_JS_REMOVEFILE>';
  var msg_show_thread1 = '<const S_JS_SHOWTHREAD1>';
  var msg_show_thread2 = '<const S_JS_SHOWTHREAD2>';

  $j = jQuery.noConflict();
  $j(document).ready(function() {
    var match;
    if ((match = /#i([0-9]+)/.exec(document.location.toString())) && !document.forms.postform.field4.value) insert(">>" + match[1] + "\n");

    $j('#postform_submit').click(function() {
        $j('.postarea').block({
                message: '<const S_JS_PLEASEWAIT>',
                css: { fontSize: '2em', color: '#000000', background: '#D7CFC0', border: '1px solid #BFB5A1' },
        });
        setTimeout($j.unblockUI, 5000);
    });

    <if $thread>
    $j('#delform').delegate('span.reflink a', 'click', function (ev) {
        var a = ev.target,
            sel = window.getSelection().toString();
        ev.preventDefault();
        insert('>>' + a.href.match(/#i(\d+)$/)[1] + '\n' + (sel ? '>' + sel.replace(/\n/g, '\n>') + '\n' : ''));
    });
    </if>

    <if ENABLE_HIDE_THREADS && !$thread>hideThreads('<const BOARD_IDENT>');</if>
  });
/* ]]> */
</script>

<if ENABLE_WEBSOCKET_NOTIFY && $thread && !$locked><script type="text/javascript" src="/static/js/websock.js"></script></if>
<script type="text/javascript" src="/static/js/context.js"></script>

</body>
</html>
};


use constant CATALOG_TEMPLATE => compile_template(
    NORMAL_HEAD_INCLUDE . q{

<hr /><div style="text-align: center;">
<loop $threads>
	<div class="catalog post" style="text-align: left; margin-right: 0.2em;">
	<if $subject><div class="subject" style="padding: 0.5em 1.2em 0 1.2em;"><var $subject></div></if>

	<if $files><div class="file_container post_body" style="padding-right: 0.5em; padding-bottom: 0.5em;"></if>
	<loop $files>
		<a target="_blank" href="<var get_reply_link($thread,0)>">
		<img src="<var expand_filename($thumbnail)>" width="<var $tn_width>" height="<var $tn_height>" alt="" /></a>
	</loop>
	<if $files></div></if>

	<div class="post_body" style="padding-right: 1.2em;"><var $comment></div>
	<span class="notice" style="position: absolute; bottom: 0; left: 0; margin-left: 0.1em; padding: 0.3em; background-color: #D7CFC0;">
	<a target="_blank" href="<var get_reply_link($num,0)>" style="color: #702802;">
		<if SHOW_FLAGS><var get_post_flag($location, $adminpost)></if>
		<const S_REPLIES><var $replycount>, <const S_FILES><var $filecount>, <const S_PAGE><var $page>
	</a></span>
	</div>
</loop>
</div><hr />

} . NORMAL_FOOT_INCLUDE);


use constant PAGE_TEMPLATE => compile_template(
    MANAGER_HEAD_INCLUDE . q{

<if $postform>
	<div class="postarea">
	<form id="postform" action="<var $self>" method="post" enctype="multipart/form-data">
	<input type="hidden" name="task" value="post" />
	<input type="hidden" name="board" value="<const BOARD_IDENT>" />
	<if $thread><input type="hidden" name="parent" value="<var $thread>" /></if>
	<if !$image_inp and !$thread and ALLOW_TEXTONLY>
		<input type="hidden" name="nofile" value="1" />
	</if>

	<div class="trap">
		<input type="text" name="name" size="31" />
		<input type="text" name="link" size="36" />
	</div>	

	<table>
	<tbody>
		<if $admin>
			<tr><td class="postblock">## Team ##</td>
			<td><label><input type="checkbox" name="as_staff" value="1" />  <const S_POSTASADMIN></label></td></tr>
			<tr><td class="postblock">HTML</td>
			<td><label><input type="checkbox" name="no_format" value="1" /> <const S_NOTAGS2></label></td></tr>
		</if>
	<if !FORCED_ANON or $admin><tr><td class="postblock"><label for="name"><const S_NAME></label></td><td><input type="text" name="field1" id="name" maxlength="<const MAX_FIELD_LENGTH>" tabindex="1" /></td></tr></if>

	<tr><td class="postblock"><label for="subject"><const S_SUBJECT></label></td><td><input type="text" name="field3" id="subject" maxlength="<const MAX_FIELD_LENGTH>" tabindex="2" />
	<input type="submit" id="postform_submit" value="<if $thread><var sprintf S_BTREPLY, '/' . BOARD_IDENT . '/' . $thread></if><if !$thread><const S_BTNEWTHREAD></if>" tabindex="5" /></td>
	</tr>

	<if $thread>
	<tr><td class="postblock"><label for="sage"><const S_SAGE></label></td>
	<td><label><input type="checkbox" name="field2" value="sage" id="sage" tabindex="3" /> <const S_SAGEDESC></label></td>
	</tr>
	</if>

	<tr><td class="postblock"><label for="field4"><const S_COMMENT></label></td>
	<td id="textField"><textarea id="field4" name="field4" cols="48" rows="6" tabindex="4"></textarea>
	</td></tr>

	<if $image_inp>
		<tr><td class="postblock"><const S_UPLOADFILE> (max. <const MAX_FILES>)</td>
		<td id="fileInput"><div><input type="file" name="file" onchange="file_input_change(<const MAX_FILES>)" /></div>
		<if $textonly_inp>[<label><input type="checkbox" name="nofile" value="on" /><const S_NOFILE> ]</label></if>
		</td></tr>
	</if>

	<tr><td class="postblock"><const S_NOKO></td>
	<td>
	<label><input name="gb2" value="board" checked="checked" type="radio" /> <const S_NOKOOFF></label>
	<label><input name="gb2" value="thread" type="radio" /> <const S_NOKOON></label>
	</td></tr>

	<if $captcha_inp>
		<tr><td class="postblock"><label for="captcha"><const S_CAPTCHA></label> (<a href="/faq">?</a>) (<var $loc>)</td>
		<td><input type="text" name="captcha" id="captcha" size="10" /> <img alt="" src="/<const CAPTCHA_SCRIPT>?key=<var get_captcha_key($thread)>&amp;dummy=<var $dummy>&amp;board=<const BOARD_IDENT>" /></td></tr>
	</if>

	<tr><td class="postblock"><label for="password"><const S_DELPASS></label></td><td><input type="password" name="password" id="password" /> <const S_DELEXPL></td></tr>
	<tr><td colspan="2">
	<div class="rules">} . include(BOARD_IDENT . "/rules.html") . q{</div></td></tr>
	</tbody>
	</table>
	</form>
	</div>
</if>

<if $locked && !$admin>
<p class="locked"><var sprintf S_THREADLOCKED, $thread></p>
</if>

<form id="delform" action="<var $self>" method="post">

<loop $threads>
	<hr />
	<if !$thread>
		<div id="thread_<var $num>" class="thread">
	</if>

	<if $thread>
		<div id="thread_<var $thread>" class="thread">
	</if>

		<loop $posts>
			} . POST_VIEW_INCLUDE . q{
		</loop>

		</div>
</loop>

<if $thread>
<div id="websock_enabled"></div>
</if>

<hr />

<if !$thread>
	<nav>
		<ul class="pagelist">
			<li>
				<if $prevpage>[<a href="<var $prevpage>"><const S_PREV></a>]</if>
				<if !$prevpage>[<const S_PREV>]</if>
			</li>
		<loop $pages>
			<li>
				<if !$current>[<a href="<var $filename>"><var $page></a>]</if>
				<if $current>[<strong><var $page></strong>]</if>
			</li>
		</loop>
			<li>
				<if $nextpage>[<a href="<var $nextpage>"><const S_NEXT></a>]</if>
				<if !$nextpage>[<const S_NEXT>]</if>
			</li>
		</ul>
		<ul class="pagelist">
			<li>[<a href="<var expand_filename('catalog')>"><const S_CATALOG></a>]</li>
		</ul>
		<ul class="pagelist">
			<li>[<a href="#top"><const S_TOP></a>]</li>
		</ul>
	</nav>
</if>
<if $thread>
	<nav>
		<ul class="pagelist">
			<li>[<a href="/<const BOARD_IDENT>/"><const S_RETURN></a>]</li>
		</ul>
		<ul class="pagelist">
			<li>[<a href="#top"><const S_TOP></a>]</li>
		</ul>
	</nav>
</if>

<div class="delete">
	<input type="hidden" name="task" value="delete" />
	<input type="hidden" name="board" value="<const BOARD_IDENT>" />
	<if $thread><input type="hidden" name="parent" value="<var $thread>" /></if>
	<input type="password" name="password" placeholder="<const S_DELKEY>" />
	<input value="<const S_DELETE>" type="submit" />
</div>

</form>

} . NORMAL_FOOT_INCLUDE);


use constant SEARCH_TEMPLATE => compile_template(
    MANAGER_HEAD_INCLUDE . q{

	<div class="postarea">
	<form id="searchform" action="<var $self>" method="post">
	<input type="hidden" name="task" value="search" />
	<input type="hidden" name="board" value="<const BOARD_IDENT>" />

	<table>
	<tbody>

		<tr><td class="postblock"><label for="search"><const S_SEARCH><br />
		<const S_MINLENGTH></label></td>
		<td><input type="text" name="find" id="search" value="<var $find>" />
		<input value="<const S_SEARCHSUBMIT>" type="submit" />
		</td></tr>

		<tr><td class="postblock"><const S_OPTIONS></td>
		<td>
		<label><input type="checkbox" name="op"      value="1" <if $oponly>checked="checked"</if> /> <const S_SEARCHOP></label><br />
		<label><input type="checkbox" name="subject" value="1" <if $insubject>checked="checked"</if> /> <const S_SEARCHSUBJECT></label><br />
		<!--<label><input type="checkbox" name="files"   value="1" <if $filenames>checked="checked"</if> /> <const S_SEARCHFILES></label><br />-->
		<label><input type="checkbox" name="comment" value="1" <if $comment>checked="checked"</if> /> <const S_SEARCHCOMMENT></label>
		</td></tr>

	</tbody>
	</table>

	</form>
	</div>

	<if $find>
		<hr />
		<const S_SEARCHFOUND> <var $count>
		<if $count><br /><br /></if>
	</if>

	<loop $posts>
		} . POST_VIEW_INCLUDE . q{
	<p style="clear: both;"></p>
	</loop>

	<hr />

} . NORMAL_FOOT_INCLUDE);


use constant SINGLE_POST_TEMPLATE => compile_template(q{
<loop $posts>
} . POST_VIEW_INCLUDE . q{
</loop>
});

use constant ERROR_HEAD_INCLUDE => q{

<!DOCTYPE html>
<html lang="<const BOARD_LANG>">
<head>
	<meta charset="<const CHARSET>" />
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<title><var $error_page></title>
	<link rel="stylesheet" type="text/css" href="/static/css/phutaba.css" />
	<link rel="shortcut icon" type="image/x-icon" href="/img/favicon.ico" />
	<link rel="icon" type="image/x-icon" href="/img/favicon.ico" />
	<link rel="apple-touch-icon-precomposed" href="/img/favicon-152.png" />
	<meta name="msapplication-TileImage" content="/img/favicon-144.png" />
	<meta name="msapplication-TileColor" content="#ECE9E2" />
	<meta name="msapplication-navbutton-color" content="#BFB5A1" />
	<meta name="msapplication-config" content="none" />
</head>

<body>
<div class="content">

<nav>
	<ul class="menu">
} . include("tpl/nav_boards.html") . q{
	</ul>

	<ul class="menu right">
} . include("tpl/nav_pages." . BOARD_LANG . ".html") . q{
	</ul>
</nav>

<header>
	<div class="header">
		<div class="banner"><a href="/"><img src="/banner.pl" alt="Banner" /></a></div>
		<div class="boardname"><const TITLE></div>
	</div>
</header>

<hr />
};

use constant ERROR_FOOT_INCLUDE => q{

<hr />
<footer>Powered by <img src="/img/phutaba_icon.png" alt="" /> <strong>Phutaba</strong>.</footer>
</div>
<const TRACKING_CODE>
</body>
</html>
};

use constant ERROR_TEMPLATE => compile_template(
    ERROR_HEAD_INCLUDE . q{

<div class="error">
	<header class="title"><var $error_title></header>

<if $error>
<div class="info"><var $error></div>
</if>

<if $banned>
<div class="info">
<img src="/img/ernstwurf_schock.png" width="210" height="210" style="float: right;" />

<loop $bans>
 <const S_BANNEDIP> <strong><var $ip></strong>
 <if $showmask>(<const S_BANNEDNET> <var $network>/<var $setbits>)</if>
 <if $reason><const S_BANNEDREASON><br /><strong><var $reason></strong></if>
 <if !$reason><const S_BANNEDNOREASON></if>
 <br /><br />
 <if $expires><var sprintf S_BANNEDEXPIRE, make_date($expires, DATE_STYLE, S_WEEKDAYS, S_MONTHS)></if>
 <if !$expires><const S_BANNEDNOEXPIRE></if>
 <br /><br />
</loop>

 <br /><const S_BANNEDCONTACT>
</div>
</if>

</div>

} . ERROR_FOOT_INCLUDE);

#
# Admin pages
#


use constant ADMIN_LOGIN_TEMPLATE => compile_template(
    MANAGER_HEAD_INCLUDE . q{

<div align="center"><form action="<var $self>" method="post">
<input type="hidden" name="task" value="admin" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />

<table><tbody>
<tr><td class="postblock"><const S_STAFFUSER></td><td><input type="text" name="user" size="24" /></td></tr>
<tr><td class="postblock"><const S_STAFFPASS></td><td><input type="password" name="berra" size="24" value="" /></td></tr>
<tr><td>&nbsp;</td><td><label><input type="checkbox" name="savelogin" /> <const S_MANASAVE></label></td></tr>
</tbody></table>

<select name="nexttask">
<option value="show"><const S_MANAPANEL></option>
<option value="bans"><const S_MANABANS></option>
</select>
<input type="submit" value="<const S_MANALOGIN>" />


</form></div>

} . NORMAL_FOOT_INCLUDE
);

use constant POST_PANEL_TEMPLATE => compile_template(
    MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MANATOOLS></div>

<div class="postarea">

<const S_MANAGEOINFO>
<table><tbody>
<tr><td class="postblock">GeoIP-API</td><td><var $geoip_api></td></tr>
<loop $geoip_results>
	<tr><td class="postblock"><var $file></td><td><var $result></td></tr>
</loop>
</tbody></table>

</div>

<br /><div class="postarea">

<const S_MANADELETE>
<form action="<var $self>" method="post">
<input type="hidden" name="task" value="deleteall" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_BANIPLABEL></td><td><input type="text" name="ip" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANMASKLABEL></td><td>
} . NETMASK_SELECT_INCLUDE . q{
<input type="submit" value="<const S_MPDELETEIP>" /></td></tr>
</tbody></table></form>

</div><br />

<var sprintf S_IMGSPACEUSAGE, get_displaysize($size, DECIMAL_MARK), $files, $posts, $threads>
<var sprintf S_POSTSTATS, make_date($o_date, '2ch'), $oldest, make_date($n_date, '2ch'), $newest>

} . NORMAL_FOOT_INCLUDE
);

use constant DELETE_PANEL_TEMPLATE => compile_template(
	MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MPDELETEIP></div>

<div class="postarea">
<form action="<var $self>" method="post">
<input type="hidden" name="task" value="deleteall" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<input type="hidden" name="ip" value="<var $ip>" />
<input type="hidden" name="mask" value="<var dec_to_dot($mask)>" />
<input type="hidden" name="go" value="1" />
<table><tbody>
<tr><td class="postblock"><const S_BANIPLABEL></td><td><var dec_to_dot($ip)></td></tr>
<tr><td class="postblock"><const S_BANMASKLABEL></td><td><var dec_to_dot($mask)></tr>
<tr><td class="postblock"><const S_BOARD></td><td>/<const BOARD_IDENT>/</tr>
<tr><td class="postblock"><const S_DELALLMSG></td><td><var sprintf S_DELALLCOUNT, $posts, $threads>
<input type="submit" value="<const S_MPDELETEIP>" /></td></tr>
</tbody></table></form>
</div>

} . NORMAL_FOOT_INCLUDE);

use constant BAN_PANEL_TEMPLATE => compile_template(
    MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MANABANS></div>

<div class="managearea">
<div class="managechild">

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="addip" />
<input type="hidden" name="type" value="ipban" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_BANIPLABEL></td><td><input type="text" name="ip" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANMASKLABEL></td><td>} . NETMASK_SELECT_INCLUDE . q{</td></tr>
<tr><td class="postblock"><const S_BANDURATION></td><td>} . DURATION_SELECT_INCLUDE . q{</td></tr>
<if $admin eq 1>
	<tr><td class="postblock"><const S_BOARD></td><td>
		<label><input name="global" value="0" type="radio" />/<const BOARD_IDENT>/</label>
		<label><input name="global" value="1" checked="checked" type="radio" /><const S_BANGLOBAL></label>
	</td></tr>
</if>
<tr><td class="postblock"><const S_BANREASONLABEL></td><td><input type="text" name="comment" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANINTERNALCOMMENTLABEL></td><td><input type="text" name="icomment" size="16" />
<input type="submit" value="<const S_BANIP>" /></td></tr>
</tbody></table></form>

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="addstring" />
<input type="hidden" name="type" value="asban" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_BANASNUMLABEL></td><td><input type="text" name="string" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANCOMMENTLABEL></td><td><input type="text" name="comment" size="16" />
<input type="submit" value="<const S_BANASNUM>" /></td></tr>
</tbody></table></form>

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="addstring" />
<input type="hidden" name="type" value="wordban" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_BANWORDLABEL></td><td><input type="text" name="string" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANCOMMENTLABEL></td><td><input type="text" name="comment" size="16" />
<input type="submit" value="<const S_BANWORD>" /></td></tr>
</tbody></table></form>

</div><div class="managechild">

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="addip" />
<input type="hidden" name="type" value="whitelist" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_BANIPLABEL></td><td><input type="text" name="ip" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANMASKLABEL></td><td>} . NETMASK_SELECT_INCLUDE . q{</td></tr>
<tr><td class="postblock"><const S_BANCOMMENTLABEL></td><td><input type="text" name="comment" size="16" />
<input type="submit" value="<const S_BANWHITELIST>" /></td></tr>
</tbody></table></form>

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="addstring" />
<input type="hidden" name="type" value="trust" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_BANTRUSTTRIP></td><td><input type="text" name="string" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANCOMMENTLABEL></td><td><input type="text" name="comment" size="16" />
<input type="submit" value="<const S_BANTRUST>" /></td></tr>
</tbody></table></form>

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="addstring" />
<input type="hidden" name="type" value="filter" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_BANWRDFLTLABEL></td><td><input type="text" name="string" size="24" /></td></tr>
<tr><td class="postblock"><const S_BANWRDREPLABEL></td><td><input type="text" name="comment" size="16" />
<input type="submit" value="<const S_BANWRDFLTADD>" /></td></tr>
</tbody></table></form>

</div>
</div><br />

<if $filter ne 'off'>[<a href="<var $self>?board=<var get_board_id()>&amp;task=bans&amp;filter=off#tbl"><const S_BANSHOWALL></a>]</if>
<if $filter eq 'off'>[<a href="<var $self>?board=<var get_board_id()>&amp;task=bans#tbl"><const S_BANFILTER></a>]</if>
<a id="tbl"></a>
<table align="center"><tbody>
<tr class="managehead"><const S_BANTABLE></tr>

<loop $bans>
	<if $divider><tr class="managehead"><th colspan="10"></th></tr></if>

	<tr class="row<var $rowtype>">

	<if $type eq 'ipban'>
		<td>IP</td>
		<td><img src="/img/flags/<var $flag>.PNG" title="<var $flag>" /> <var dec_to_dot($ival1)></td><td>/<var $masklen></td>
	</if>
	<if $type eq 'wordban'>
		<td>Word</td>
		<td colspan="2"><var $sval1></td>
	</if>
	<if $type eq 'trust'>
		<td>NoCap</td>
		<td colspan="2"><var $sval1></td>
	</if>
	<if $type eq 'whitelist'>
		<td>Whitelist</td>
		<td><img src="/img/flags/<var $flag>.PNG" title="<var $flag>" /> <var dec_to_dot($ival1)></td><td>/<var $masklen></td>
	</if>
	<if $type eq 'asban'>
		<td>ASNum</td>
		<td colspan="2"><var $sval1></td>
	</if>
	<if $type eq 'filter'>
		<td>Filter</td>
		<td colspan="2"><var $sval1></td>
	</if>

	<td><var $comment></td>
	<td><var $icomment></td>
	<td>
	<if $type eq 'ipban'><var $boards></if>
	<if $type ne 'ipban'>-</if>
	</td>
	<td>
		<if $date>
			<var $date>
		</if>
		<if !$date>
			<i>none</i>
		</if>
	</td>	
	<td>
	<if $type eq 'ipban'>
		<if $sval1><var make_date($sval1, '2ch')></if>
		<if !$sval1>never</if>
	</if>
	<if $type ne 'ipban'>-</if>
	</td>
	<td><var $user></td>
	<td><a href="<var $self>?task=removeban&amp;board=<var get_board_id()>&amp;num=<var $num>"><const S_BANREMOVE></a></td>
	</tr>
</loop>

</tbody></table><br />

} . NORMAL_FOOT_INCLUDE
);


use constant ADMIN_ORPHANS_TEMPLATE => compile_template(
    MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MANAORPH>, <const S_BOARD>: /<const BOARD_IDENT>/ (<var $file_count> Files, <var $thumb_count> Thumbs)</div>

<div class="postarea">

<form action="<var $self>" method="post">

<table><tbody>
	<tr class="managehead"><const S_ORPHTABLE></tr>
	<loop $files>
		<tr class="row<var $rowtype>">
		<td><a target="_blank" href="<var expand_filename($name)>"><const S_MANASHOW></a></td>
		<td><label><input type="checkbox" name="file" value="<var $name>" checked="checked" /><var $name></label></td>
		<td><var make_date($modified, '2ch')></td>
		<td align="right"><var get_displaysize($size, DECIMAL_MARK)></td>
		</tr>
	</loop>
</tbody></table><br />

<loop $thumbs>
	<div class="file">
	<label><input type="checkbox" name="file" value="<var $name>" checked="checked" /><var $name></label><br />
	<var make_date($modified, '2ch')> (<var get_displaysize($size, DECIMAL_MARK)>)<br />
	<img src="<var expand_filename($name)>" />
	</div>
</loop>

<p style="clear: both;"></p>

<input type="hidden" name="task" value="movefiles" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<input value="<const S_MPARCHIVE>" type="submit" />
</form>

</div>

} . NORMAL_FOOT_INCLUDE
);


use constant ADMIN_EDIT_TEMPLATE => compile_template(
    MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MPEDIT> (/<const BOARD_IDENT>/<var $postid>)</div>

<div align="center"><em><const S_NOTAGS></em></div>

<div class="postarea">
<form action="<var $self>" method="post">
<input type="hidden" name="task" value="save" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<input type="hidden" name="post" value="<var $postid>" />

<table><tbody>
	<tr><td class="postblock"><label for="name"><const S_NAME></label></td><td><input type="text" name="field1" id="name" value="<var $name>" /></td></tr>
	<tr><td class="postblock"><label for="subject"><const S_SUBJECT></label></td><td><input type="text" name="field3" id="subject" value="<var $subject>" />
	<input type="submit" value="<const S_SUBMIT>" /></td></tr>
	<tr><td class="postblock"><label for="field4"><const S_COMMENT></label></td>
	<td id="textField"><textarea id="field4" name="field4" cols="80" rows="14"><var $comment></textarea>
	</td></tr>
</tbody></table></form></div><hr />


} . NORMAL_FOOT_INCLUDE
);


use constant LOG_PANEL_TEMPLATE => compile_template(
	MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MANALOG></div>

[<a href="<var $self>?board=<var get_board_id()>&amp;task=log&amp;filter=<var $filter>&amp;show=<var !$show>"><if $filter><const S_LOGFILTEROFF></if><if !$filter><const S_LOGFILTERON></if></a>]
[<a href="<var $self>?board=<var get_board_id()>&amp;task=log&amp;filter=<var !$filter>&amp;show=<var $show>"><if $show><const S_LOGCOMMENTSSHOW></if><if !$show><const S_LOGCOMMENTSHIDE></if></a>]

<table align="center"><tbody>
<tr class="managehead"><const S_LOGTABLE></tr>

<loop $log>
	<tr class="row<var $rowtype>">
		<td><var make_date($timestamp, '2ch')></td>
		<td><var $event></td>
		<td><var $user></td>
		<td><var $reflink></td>
		<td><if $ip><var dec_to_dot($ip)></if><if !$ip>-</if></td>
		<td><var $preview></td>
	</tr>
	<if $posttext><tr class="row<var $rowtype>"><td colspan="6"><var $posttext></td></tr></if>
</loop>

</tbody></table><br />

} . NORMAL_FOOT_INCLUDE
);


use constant STAFF_PANEL_TEMPLATE => compile_template(
	MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MANASTAFF></div>

<div class="postarea">
<table><tbody><tr><td valign="bottom">

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="adduser" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<table><tbody>
<tr><td class="postblock"><const S_STAFFUSER></td><td><input type="text" name="user" size="24" /></td></tr>
<tr><td class="postblock"><const S_STAFFPASS></td><td><input type="password" name="password1" size="24" /></td></tr>
<tr><td class="postblock"><const S_PASSNEW2></td><td><input type="password" name="password2" size="24" /></td></tr>
<tr><td class="postblock"><const S_ACCOUNTTYPE></td><td>
<label><input type="radio" name="type" value="1"><const S_ACCOUNTADMIN></label>&nbsp;
<label><input type="radio" name="type" value="2" checked="checked"><const S_ACCOUNTMOD></label>&nbsp;&nbsp;
<input type="submit" value="<const S_ACCOUNTNEW>" />
</td></tr>

</tbody></table></form>

</td></tr></tbody></table>
</div><br />

<table align="center"><tbody>
<tr class="managehead"><const S_ACCOUNTTABLE></tr>

<loop $users>
        <if $divider><tr class="managehead"><th colspan="6"></th></tr></if>

        <tr class="row<var $rowtype>">

		<td>
			<if $type == 1><const S_ACCOUNTADMIN></if>
			<if $type == 2><const S_ACCOUNTMOD></if>
		</td>

		<td><var $user></td>

		<td>
			<if $enabled>
				<const S_ACCOUNTENABLED>
				<if $num ne $current>
				<a href="<var $self>?task=disableuser&amp;board=<var get_board_id()>&amp;num=<var $num>"><const S_ACCOUNTDISABLE></a>
				</if>
			</if>
			<if !$enabled>
				<const S_ACCOUNTDISABLED>
				<a href="<var $self>?task=enableuser&amp;board=<var get_board_id()>&amp;num=<var $num>"><const S_ACCOUNTENABLE></a>
			</if>
		</td>

		<td><a href="<var $self>?task=changepass&amp;board=<var get_board_id()>&amp;num=<var $num>"><const S_ACCOUNTPASS></a></td>

        <td><if $timestamp><var make_date($timestamp, 'date', S_WEEKDAYS, S_MONTHS)></if></td>

        <td>
			<if $num ne $current && $user ne "admin">
				<a href="<var $self>?task=removeuser&amp;board=<var get_board_id()>&amp;num=<var $num>"><const S_ACCOUNTREMOVE></a>
			</if>
		</td>

        </tr>
</loop>

</tbody></table><br />

} . NORMAL_FOOT_INCLUDE
);



use constant CHANGE_PASSWORD_TEMPLATE => compile_template(
	MANAGER_HEAD_INCLUDE . q{

<div class="dellist"><const S_MANAPASS></div>

<div class="postarea">
<table><tbody><tr><td valign="bottom">

<form action="<var $self>" method="post">
<input type="hidden" name="task" value="changepass" />
<input type="hidden" name="board" value="<const BOARD_IDENT>" />
<input type="hidden" name="num" value="<var $num>" />

<table><tbody>
<tr><td class="postblock"><const S_STAFFUSER></td><td><var $user></td></tr>
<if !$pwreset>
<tr><td class="postblock"><const S_PASSOLD></td><td><input type="password" name="oldpw" size="24" /></td></tr>
</if>
<tr><td class="postblock"><const S_PASSNEW1></td><td><input type="password" name="newpw1" size="24" /></td></tr>
<tr><td class="postblock"><const S_PASSNEW2></td><td><input type="password" name="newpw2" size="24" />
&nbsp;&nbsp;<input type="submit" value="<const S_MANAPASS>" />
</td></tr>
</tbody></table></form>
<br /><var $msg>

</td></tr></tbody></table>
</div><br />

} . NORMAL_FOOT_INCLUDE
);


1;
