## post form
use constant S_NAME        => 'Name';           # Describes name field
use constant S_SUBJECT     => 'Subject';        # Describes subject field
use constant S_BTNEWTHREAD => 'Create new thread';
use constant S_BTREPLY     => 'Reply to %s';
use constant S_SAGE        => 'Kontra';
use constant S_SAGEDESC    => 'Do not bump thread';
use constant S_COMMENT     => 'Comment';      # Describes comment field
use constant S_UPLOADFILE  => 'File';          # Describes file field
use constant S_NOFILE      => 'No file';    # Describes file/no file checkbox
use constant S_NOKO        => 'Return to';
use constant S_NOKOOFF     => 'Board';
use constant S_NOKOON      => 'Thread';
use constant S_CAPTCHA     => 'Captcha';        # Describes captcha field
use constant S_DELPASS     => 'Password';    # Describes password field
use constant S_DELEXPL     => '(optional)';    # Prints explanation for password box (to the right)
use constant S_ALLOWED => 'Allowed file extensions (max. size %s or specified)';

# if post form not shown in locked threads
use constant S_THREADLOCKED => '<strong>Thread %s</strong> is locked. No replys can be posted.';

## thread / post header
use constant S_HIDE => 'Hide thread %d';
use constant S_POSTNO  => 'No.';
use constant S_STICKYTITLE => 'Thread is sticky'
  ;    # Defines the title of the tiny sticky image on a thread if it is sticky
use constant S_LOCKEDTITLE => 'Thread is locked'
  ;    # Defines the title of the tiny locked image on a thread if it is locked
use constant S_BUMPLIMIT => 'Systemkontra';
use constant S_REPLY   => 'Reply';    # Prints text for reply link

# post files / tooltips
use constant S_FILEINFO => 'Information';
use constant S_FILENAME => 'File name';
use constant S_FILEDELETED => 'File deleted';
use constant S_PICNAME => '';             # Prints text before upload name/link

## abbreviations on board page
use constant S_ABBR1 => '1 post ';				# Prints text to be shown when replies are hidden
use constant S_ABBR2 => '%d posts ';
use constant S_ABBRIMG1 => 'and 1 file ';		# Prints text to be shown when replies and files are hidden
use constant S_ABBRIMG2 => 'and %d files ';
use constant S_ABBR_END => 'omitted';

use constant S_ABBRTEXT1 => 'Show 1 more line';
use constant S_ABBRTEXT2 => 'Show %d more lines';

use constant S_BANNED  => '(User was banned for this post)';

## catalog strings
use constant S_REPLIES => 'Replies: ';
use constant S_FILES => 'Files: ';
use constant S_PAGE => 'Page: ';

## bottom page navigation
use constant S_PREV   => 'Previous';    # Defines previous button
use constant S_NEXT   => 'Next';            # Defines next button
use constant S_TOP    => 'Top';
use constant S_BOTTOM => 'Bottom';
use constant S_CATALOG => 'Catalog';
use constant S_RETURN => 'Return'; # Returns from thread back to image board

## bottom page delete form
use constant S_DELKEY => 'Password';    # Prints text next to password field for deletion (left)
use constant S_DELETE => 'Delete';    # Defines deletion button's name


# javascript message strings (mask single quotes with \\\')
use constant S_JS_REMOVEFILE => 'Remove file';
use constant S_JS_PLEASEWAIT => 'Please wait &hellip;';
use constant S_JS_SHOWTHREAD1 => 'Show thread ';
use constant S_JS_SHOWTHREAD2 => '';
# javascript strings END


## search page
use constant S_SEARCHTITLE		=> 'Suche';
use constant S_SEARCH			=> 'Suchen nach';
use constant S_SEARCHCOMMENT	=> 'Kommentar durchsuchen';
use constant S_SEARCHSUBJECT	=> 'Betreff durchsuchen';
use constant S_SEARCHFILES		=> 'Dateinamen durchsuchen';
use constant S_SEARCHOP			=> 'Nur im OP eines Threads suchen';
use constant S_SEARCHSUBMIT		=> 'Suchen';
use constant S_SEARCHFOUND		=> 'Ergebnisse:';
use constant S_OPTIONS			=> 'Optionen';
use constant S_MINLENGTH		=> '(min. 3 Zeichen)';


## banned error page
use constant S_BANNEDIP => 'Your IP address';
use constant S_BANNEDNET => 'network';

use constant S_BANNEDREASON => 'was banned with the following reason:';
use constant S_BANNEDNOREASON => 'was banned.';

use constant S_BANNEDEXPIRE => 'This ban expires on <strong>%s</strong>.';
use constant S_BANNEDNOEXPIRE => 'The expiration of this ban is undetermined.';

use constant S_BANNEDCONTACT => 'Please contact us in the IRC if you want to post again!';


## date strings
use constant S_WEEKDAYS => 'Su Mo Tu We Th Fr Sa'
  ;                                         # Defines abbreviated weekday names.
use constant S_MONTHS => 'January February March April May June July August September October November December'
  ;                                         # Defines long month names


## admin / management strings

# admin login page
use constant S_STAFFUSER => 'User';
use constant S_STAFFPASS => 'Password';
use constant S_ADMINPASS => 'Password:';    # Prints login prompt
use constant S_MANASAVE  => 'Save session in this browser';    # Defines Label for the login cookie checbox
use constant S_MANALOGIN => 'Login'
  ; # Defines Management Panel radio button--allows the user to view the management panel (overview of all posts)

# admin pages links / headings
use constant S_MANAPANEL => 'Post moderation'
  ; # Defines Management Panel radio button--allows the user to view the management panel (overview of all posts)
use constant S_MANABANS   => 'Manage bans';         # Defines Bans Panel button
use constant S_MANATOOLS  => 'Tools';
use constant S_MANAORPH   => 'Orphaned files';
use constant S_MANALOG    => 'Show log';
use constant S_MANASTAFF  => 'Staff accounts';
use constant S_MANAPASS   => 'Change password';
use constant S_MANALOGOUT => 'Logout';          #

use constant S_MANAMODE => 'Administration';   # Prints heading on top of Manager page
use constant S_MANARET => 'Return'
  ;    # Returns to HTML file instead of PHP--thus no log/SQLDB update occurs
use constant S_BOARD   => 'Board';

# admin tools page
use constant S_MANAGEOINFO => 'GeoIP information';
use constant S_MANADELETE => 'Delete posts';
use constant S_MPDELETEIP => 'Delete all';
use constant S_DELALLMSG => 'Affected';
use constant S_DELALLCOUNT => '%d posts (%d threads)';
use constant S_IMGSPACEUSAGE => '[ Used disk space: %s, %d files, %d posts (%d threads) ]'
  ;          # Prints space used KB by the board under Management Panel
use constant S_POSTSTATS => '[ Oldest post: %s (No. %d), newest post: %s (No. %d) ]';

# admin orphans
use constant S_ORPHTABLE  => '<th>Open</th><th>File</th><th>Modified</th><th>Size</th>';
use constant S_MANASHOW   => 'Open';
use constant S_MPARCHIVE  => 'Archive';

# admin log
use constant S_LOGTABLE => '<th>Date</th><th>Event</th><th>User</th><th>Link</th><th>IP</th><th>Comment (fraction)</th>';
use constant S_LOGFILTERON => 'Show the last 100 events';
use constant S_LOGFILTEROFF => 'Show all events';
use constant S_LOGCOMMENTSSHOW => 'Show full comments';
use constant S_LOGCOMMENTSHIDE => 'Hide full comments';

# admin staff accounts
use constant S_ACCOUNTTABLE => '<th>Type</th><th>Name</th><th>Status</th><th>Password</th><th>Last Activity</th><th>Action</th>';
use constant S_ACCOUNTNEW => 'Add account';
use constant S_ACCOUNTTYPE => 'Type';
use constant S_ACCOUNTADMIN => 'Admin';
use constant S_ACCOUNTMOD => 'Mod';
use constant S_ACCOUNTENABLED => 'Enabled';
use constant S_ACCOUNTDISABLED => 'Disabled';
use constant S_ACCOUNTENABLE => '(enable)';
use constant S_ACCOUNTDISABLE => '(disable)';
use constant S_ACCOUNTPASS => 'Change';
use constant S_ACCOUNTREMOVE => 'Remove';
use constant S_ACCOUNTEXISTS => 'User already exists.';

# staff change password
use constant S_PASSOLD  => 'Current password';
use constant S_PASSNEW1 => 'New password';
use constant S_PASSNEW2 => 'Confirm password';
use constant S_PWCHANGEERR1 => 'Error: New password and confirmation do not match.';
use constant S_PWCHANGEERR2 => 'Error: Current password wrong.';
use constant S_PWCHANGEFAIL => 'Password not changed.';
use constant S_PWCHANGEOK   => 'Password for user <i>%s</i> changed successfully.';

# post edit heading
use constant S_NOTAGS => 'Use HTML for formatting. Text will not be parsed.'
  ;               # Prints message on Management Board
use constant S_SUBMIT     => 'Submit';     # Describes submit button

# admin post options
use constant S_POSTASADMIN => 'Show admin ID on post';
use constant S_NOTAGS2 => 'Do not parse comment';

# admin board page tooltip
use constant S_POSTINFO => 'IP address information'; # admin post info tooltip heading

## admin post buttons
# thread buttons
use constant S_MPSTICKY    => 'Make sticky';
use constant S_MPUNSTICKY  => 'Remove sticky';
use constant S_MPLOCK      => 'Lock thread';
use constant S_MPUNLOCK    => 'Unlock thread';
use constant S_MPSETSAGE   => 'Set bumplock';
use constant S_MPUNSETSAGE => 'Remove bumplock';

use constant S_MPEDIT      => 'Edit post comment';
use constant S_MPBAN       => 'Ban';
use constant S_MPDELETEALL => 'Delete all posts of this IP address';
use constant S_MPDELFILE   => 'Delete file(s)';
use constant S_MPDELETE    => 'Delete post';    # Defines for deletion button in Management Panel


## admin ban page

# top forms
# ban form / jquery ban dialog
use constant S_BANIPLABEL      => 'IP address';
use constant S_BANMASKLABEL    => 'Network mask';
use constant S_BANDURATION     => 'Duration';
use constant S_BANREASONLABEL  => 'Reason';
use constant S_BANINTERNALCOMMENTLABEL => 'Note';
use constant S_BANFLAGPOST     => 'Flag post as banned';
use constant S_BANGLOBAL       => 'On all boards';
use constant S_BANIP           => 'Ban IP'; # ip ban submit
use constant S_BANADDED        => 'New ban added'; # json response
use constant S_BANFOUND        => 'User is already banned'; # json response

use constant S_BANCOMMENTLABEL => 'Comment';
use constant S_BANWHITELIST    => 'Whitelist'; # ip whitlist submit
use constant S_BANWORDLABEL    => 'Word';
use constant S_BANWORD         => 'Ban word'; # submit
use constant S_BANTRUSTTRIP    => 'Tripcode';
use constant S_BANTRUST        => 'No captcha'; # trip whitelist submit
use constant S_BANASNUMLABEL   => 'AS number';
use constant S_BANASNUM        => 'Ban network'; # ban asn submit
use constant S_BANWRDFLTLABEL  => 'Search expression';
use constant S_BANWRDREPLABEL  => 'Replace by';
use constant S_BANWRDFLTADD    => 'Add wordfilter';  # word filter submit

# bans table bottom
use constant S_BANFILTER => 'Hide expired bans';
use constant S_BANSHOWALL => 'Also show expired bans';
use constant S_BANTABLE =>
  '<th>Type</th><th colspan="2">Value</th><th>Comment / Ban reason</th><th>Note</th><th>Board</th><th>Created</th><th>Expires</th><th>Account</th><th>Action</th>'
  ;          # Explains names for Ban Panel
use constant S_BANREMOVE       => 'Remove';

# admin error messages
use constant S_WRDFLTINVALID => 'Wordfilter string too short or too long or contains invalid characters.';


## error messages
# show page errors
use constant S_ERRORTITLE   => 'Error';
use constant S_INVALID_PAGE => "Error: Page not found.";
use constant S_STOP_FOOLING => "Stop fooling!";
use constant S_NOTHREADERR  => 'Error: Thread does not exist.'
  ;    # Returns error when a non-existant thread is accessed
use constant S_NOREC =>
  'Error: Post not found.'; # Returns error when record cannot be found
# posting errors
use constant S_LOCKED    => 'Thread is locked.';
use constant S_BADDELIP  => 'Error: Wrong IP address.'
  ;    # Returns error for wrong ip (when user tries to delete file)
use constant S_BADDELPASS => 'Error: Wrong password for post deletion.'
  ;    # Returns error for wrong password (when user tries to delete file)

use constant S_TOOBIG       => 'File too big.';
use constant S_TOOBIGORNONE => 'File too big or empty.';
use constant S_BADFORMAT => 'Error: File type or format not supported.'
  ;    # Returns error when the file is not in a supported format.

use constant S_NOCAPTCHA => 'Error: Cannot find captcha for this key.'
  ;    # Returns error when there's no captcha in the database for this IP/key
use constant S_BADCAPTCHA =>
  'Error: Wrong captcha code.';    # Returns error when the captcha is wrong

use constant S_STRREF =>
  'Error: String refused.';    # Returns error when a string is refused
use constant S_UNJUST => 'Error: Flood detected.'
  ; # Returns error on an unjust POST - prevents floodbots or ways not using POST method?
use constant S_NOPIC => 'Error: No file selected.'
  ;    # Returns error for no file selected and override unchecked
use constant S_NOTEXT => 'Error: No comment entered.'
  ;    # Returns error for no text entered in to subject/comment
use constant S_TOOLONG1 => 'Error: Text in field name, subject or e-mail is too long.';
use constant S_TOOLONG2 => 'Error: Comment too long.'
  ;    # Returns error for too many characters in a given field
use constant S_NOTALLOWED1 =>
  'Error: New threads must contain a file.';    # Returns error for non-allowed post types
use constant S_NOTALLOWED2 =>
  'Error: New threads are not allowed to contain a file.';
use constant S_NOTALLOWED3 => 'Error: Replies must contain a file.';
use constant S_NOTALLOWED4 => 'Error: Replies are not allowed to contain a file.';
use constant S_UNUSUAL => 'Error: Stop messing around.'
  ;    # Returns error for abnormal reply? (this is a mystery!)

use constant S_BADHOST => 'Error: IP address is banned.'
  ;    # Returns error for banned host ($badip string)
use constant S_BADHOSTPROXY => 'Error: Proxy is banned.'
  ;    # Returns error for banned proxy ($badip string)
use constant S_ASBAN => 'AS network banned';
use constant S_AUTOBAN => 'Spambot [Auto Ban]'; # Ban reason for automatically created bans
use constant S_RENZOKU =>
  'Error: Too many posts submitted.';    # Returns error for $sec/post spam filter
use constant S_RENZOKU2 =>
  'Error: Too many posts submitted.';    # Returns error for $sec/upload spam filter
use constant S_RENZOKU3 =>
  'Error: Too many posts submitted.';    # Returns error for $sec/similar posts spam filter.
use constant S_RENZOKU4 =>
  'Error: Deletion timeout not expired.';    # Returns error for too early post deletion.
use constant S_RENZOKU5 =>
  'Error: Too many threads submitted. Please wait before creating more threads.';    # Returns error for too many threads spam filter.

use constant S_DUPE =>
  'Error: This file has already been uploaded <a href="%s">here</a>.'
  ;    # Returns error when an md5 checksum already exists.
use constant S_DUPENAME =>
  'Error: A file with this name already exists.'
  ;    # Returns error when an filename already exists.

use constant S_WRONGPASS => 'Error: Wrong password / please login again.'
  ;    # Returns error for wrong password (when trying to access Manager modes)
use constant S_BADSESSION => 'Error: Session invalild. Please log in again.';	# Returns error for wrong session ID (when trying to access Manager modes)
use constant S_BADACCOUNT => 'Error: Account disabled';					# Returns error for disabled account (when trying to access Manager modes)
use constant S_NOPRIV => 'Error: No permission';						# Returns error when mod tries to access or execute admin functions.

use constant S_NOTWRITE =>
  'Error: Cannot to write to directory.'
  ; # Returns error when the script cannot write to the directory, the chmod (777) is wrong
use constant S_SPAM => 'Spam? Scram!';   # Returns error when detecting spam

use constant S_SQLCONF => 'SQL connection error'; # Database connection failure
use constant S_SQLFAIL => 'SQL database error'; # SQL Failure


use constant TOOLTIP_TAGS => (
	LC_1Page => '1 page',
	LC_Pages => '%d pages',
	LC_1File => '1 file',
	LC_Files => '%d files',
	LC_Archive => '<strong>Archive with %s:</strong>',
	LC_Omitted => '<em>(%d more not shown)</em>',
	LC_Codec => 'Codec',

	"FileSize" => "File size",
	"FileType" => "File type",
	"ImageSize" => "Resolution",
	"ModifyDate" => "Modfied",
	"Comment" => "Comment",
	"Comment-xxx" => "Comment (2)",
	"CreatorTool" => "Creator tool",
	"Software" => "Software",
	"MIMEType" => "Content type",
	"Producer" => "Software",
	"Creator" => "Creator",
	"Author" => "Author",
	"Subject" => "Subject",
	"PDFVersion" => "PDF version",
	"PageCount" => "Page count",
	"Title" => "Title",
	"Duration" => "Duration",
	"Artist" => "Artist",
	"AudioBitrate" => "Bitrate",
	"ChannelMode" => "Channel mode",
	"Compression" => "Compression method",
	"FrameCount" => "Frames",
	"Vendor" => "Library vendor",
	"Album" => "Album",
	"Genre" => "Genre",
	"Composer" => "Composer",
	"Model" => "Model",
	"Maker" => "Maker",
	"OwnerName" => "Owner",
	"CanonModelID" => "Canon model ID",
	"UserComment" => "Comment (3)",
	"GPSPosition" => "Position",
	"Publisher" => "Publisher",
	"Language" => "Language",
	"AudioChannels" => "Audio channels",
	"Channels" => "Channels",
	"VideoFrameRate" => "Frame rate",
);


1;
