use constant POST_VIEW_INCLUDE => q{

<if !$parent>
	<div class="thread_OP" id="<var $num>">
	<div class="post">
	<header class="thread_head">
</if>

<if $parent>
	<div class="thread_reply" id="<var $num>">
	<div class="doubledash desktop">
	<a href="<var get_reply_link($parent,0)>#<var $num>">&gt;&gt;</a>
	</div>

	<div class="post<if $single> post_new</if>">
	<div class="post_head">
</if>

	<if ENABLE_HIDE_THREADS && !$thread && !$parent>
		<span class="togglethread">
		<img src="/img/icons/hide.png" title="<var sprintf S_HIDE, $num>" alt="Hide" onclick="hideThread('<var $num>', '<const BOARD_IDENT>');" />
		</span>
	</if>

	<label>
		<input type="checkbox" name="delete" value="<var $num>" />
		<span class="subject"><var $subject></span>
		<if SHOW_FLAGS && !$adminpost><var get_post_flag($location)></if>
        <span class="postername"><var $name><if $trip><span class="tripcode"><var $trip></span></if></span>
		<if $adminpost><span class="teampost">## Team ##</span></if>
		<span class="date desktop"><var make_date($timestamp, DATE_STYLE, S_WEEKDAYS, S_MONTHS)></span>
		<span class="date mobile"><var make_date($timestamp, '2ch')></span>
	</label>

	<if SSL_ICON && $secure>
		<span onmouseover="Tip('<var $secure>')" onmouseout="UnTip()"><img src="<const SSL_ICON>" alt="" /></span>
	</if>

	<span class="reflink">
                <if !$parent>
                        <a href="<var get_reply_link($num,0)>#i<var $num>"><const S_POSTNO>&nbsp;<var $num></a>
                </if>			
                <if $parent>
                        <a href="<var get_reply_link($parent,0)>#i<var $num>"><const S_POSTNO>&nbsp;<var $num></a>
                </if>
	</span>

	<if !$parent>
		<if $sticky><span class="sticky"><img src="/img/icons/pin.png" onmouseover="Tip('<const S_STICKYTITLE>')" onmouseout="UnTip()" alt="Pin" /></span></if>
		<if $locked><span class="locked"><img src="/img/icons/locked.png" onmouseover="Tip('<const S_LOCKEDTITLE>')" onmouseout="UnTip()" alt="Lock" /></span></if>
		<if !$autosage><if $email><span class="sage"><const S_SAGE></span></if></if>
		<if !$sticky><if $autosage><span class="sage"><const S_BUMPLIMIT></span></if></if>
	</if>

	<if $parent>
		<if $email><span class="sage"><const S_SAGE></span></if>
	</if>

	<if !$parent && !$thread>	
		<span class="replylink">[<a href="<var get_reply_link($num,0)>"><const S_REPLY></a>]</span>
	</if>

	<if $admin>
		<if !$adminpost>
		<div class="hidden" id="postinfo_<var $num>">
			<var get_post_info($location, get_board_id())>
		</div>
		<span onmouseover="TagToTip('postinfo_<var $num>', TITLE, '<const S_POSTINFO>', DELAY, 0, CLICKSTICKY, true)" onmouseout="UnTip()">[<var dec_to_dot($ip)>]</span>
		</if>
		<if !$parent>	
			<if !$sticky>
				<span onmouseover="Tip('<const S_MPSTICKY>')" onmouseout="UnTip()"><a href="<var $self>?task=sticky&amp;board=<var get_board_id()>&amp;thread=<var $num>"><img src="/img/icons/sticky.png" alt="" /></a></span>
			</if>

			<if $sticky>
				<span onmouseover="Tip('<const S_MPUNSTICKY>')" onmouseout="UnTip()"><a href="<var $self>?task=sticky&amp;board=<var get_board_id()>&amp;thread=<var $num>"><img src="/img/icons/unsticky.png" alt="" /></a></span>
			</if>
			
			<if !$locked>
				<span onmouseover="Tip('<const S_MPLOCK>')" onmouseout="UnTip()"><a href="<var $self>?task=lock&amp;board=<var get_board_id()>&amp;thread=<var $num>"><img src="/img/icons/lock.png" alt="" /></a></span>
			</if>

			<if $locked>
				<span onmouseover="Tip('<const S_MPUNLOCK>')" onmouseout="UnTip()"><a href="<var $self>?task=lock&amp;board=<var get_board_id()>&amp;thread=<var $num>"><img src="/img/icons/unlock.png" alt="" /></a></span>
			</if>
		
			<if !$autosage>
				<span onmouseover="Tip('<const S_MPSETSAGE>')" onmouseout="UnTip()"><a href="<var $self>?task=kontra&amp;board=<var get_board_id()>&amp;thread=<var $num>"><img src="/img/icons/sage.png" alt="" /></a></span>
			</if>

			<if $autosage>
				<span onmouseover="Tip('<const S_MPUNSETSAGE>')" onmouseout="UnTip()"><a href="<var $self>?task=kontra&amp;board=<var get_board_id()>&amp;thread=<var $num>"><img src="/img/icons/unsage.png" alt="" /></a></span>
			</if>
			
		</if>
		<span onmouseover="Tip('<const S_MPEDIT>')" onmouseout="UnTip()"><a href="<var $self>?task=edit&amp;board=<var get_board_id()>&amp;post=<var $num>"><img src="/img/icons/edit.png" alt="" /></a></span>
		<if !$adminpost>
		<span onmouseover="Tip('<const S_MPBAN>')"       onmouseout="UnTip()"><a onclick="do_ban('<var dec_to_dot($ip)>', <var $num>, '<const BOARD_IDENT>')"><img src="/img/icons/ban.png" alt="" /></a></span>
		<span onmouseover="Tip('<const S_MPDELETEALL>')" onmouseout="UnTip()"><a href="<var $self>?task=deleteall&amp;board=<var get_board_id()>&amp;ip=<var $ip>"><img src="/img/icons/delete_all.png" alt="" /></a></span>
		</if>
		<span onmouseover="Tip('<const S_MPDELFILE>')"   onmouseout="UnTip()"><a href="<var $self>?task=delete&amp;board=<var get_board_id()>&amp;delete=<var $num>&amp;fileonly=on"><img src="/img/icons/delete_file.png" alt="" /></a></span>
		<span onmouseover="Tip('<const S_MPDELETE>')"    onmouseout="UnTip()"><a href="<var $self>?task=delete&amp;board=<var get_board_id()>&amp;delete=<var $num>"><img src="/img/icons/delete.png" alt="" /></a></span>
	</if>

<if $parent>
	</div>
</if>

<if !$parent>
	</header>
</if>

<if $files><div class="file_container post_body"></if>
<loop $files>

<if $thumbnail><div class="file"></if>
<if !$thumbnail><div class="file filebg"></if>
	<div class="hidden" id="imageinfo_<var md5_hex($image)>">
		<strong><const S_FILENAME>:</strong> <var $uploadname><br />
		<var get_pretty_html($info_all, "\n\t\t")>
	</div>
	<div class="filename"><const S_PICNAME><a target="_blank" title="<var $uploadname>" href="<var expand_image_filename($image)>/<var get_urlstring($uploadname)>"><var $displayname></a></div>
	<div class="filesize"><var get_displaysize($size, DECIMAL_MARK)><if $width && $height>, <var $width>&nbsp;&times;&nbsp;<var $height></if><if $info>, <var $info></if></div>
	<if $thumbnail>
		<div class="filelink" onmouseover="TagToTip('imageinfo_<var md5_hex($image)>', TITLE, '<const S_FILEINFO>', WIDTH, -450)" onmouseout="UnTip()">
		<a target="_blank" href="<var expand_image_filename($image)>">
			<img <if get_extension($image) eq 'JPG' or get_extension($image) eq 'PNG' or get_extension($image) eq 'GIF'>onclick="return expand_image(this, <var $width>, <var $height>, <var $tn_width>, <var $tn_height>, '<var expand_filename($thumbnail)>')"</if>
				src="<var expand_filename($thumbnail)>" width="<var $tn_width>" height="<var $tn_height>" alt="<var $size>" />
		</a>
		</div>
	</if>
	<if !$thumbnail>
		<if !$size>
			<div class="filedeleted"><const S_FILEDELETED></div>
		</if>
		<if $size>
			<if DELETED_THUMBNAIL>
				<a target="_blank" href="<var expand_image_filename(DELETED_IMAGE)>">
					<img src="<var expand_filename(DELETED_THUMBNAIL)>" width="<var $tn_width>" height="<var $tn_height>" alt="" />
				</a>
			</if>
			<if !DELETED_THUMBNAIL>
				<div class="filetype" onmouseover="TagToTip('imageinfo_<var md5_hex($image)>', TITLE, '<const S_FILEINFO>', WIDTH, -450)" onmouseout="UnTip()">
					<a target="_blank" href="<var expand_image_filename($image)>">
						<var get_extension($uploadname)>
					</a>
				</div>
			</if>
		</if>		
	</if>
</div>

</loop>
<if $files></div></if>

	<div class="text">
		<if $abbrev>
			<div class="hidden" id="posttext_full_<var $num>">
				<var $comment_full>
			</div>
		</if>

		<div id="posttext_<var $num>" class="post_body">
			<var $comment>
			<if $abbrev>
				<p class="tldr">
					[<a href="<var get_reply_link($num,$parent)>" onclick="return expand_post('<var $num>')"><var $abbrev></a>]
				</p>
			</if>
		</div>
		<if $banned><p class="ban post_body"><const S_BANNED></p></if>
	</div>

</div>
</div>

<if !$parent>
	<if $omitmsg>
		<aside class="omittedposts">
			<var $omitmsg>
		</aside>
	</if>
</if>

};

1;
