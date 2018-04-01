## post form
use constant S_NAME        => 'Name';           # Describes name field
use constant S_SUBJECT     => 'Betreff';        # Describes subject field
use constant S_BTNEWTHREAD => 'Neuen Thread erstellen';
use constant S_BTREPLY     => 'Antworten auf %s';
use constant S_SAGE        => 'Kontra';
use constant S_SAGEDESC    => 'Thread nicht sto&szlig;en';
use constant S_COMMENT     => 'Kommentar';      # Describes comment field
use constant S_UPLOADFILE  => 'Datei';          # Describes file field
use constant S_NOFILE      => 'Keine Datei';    # Describes file/no file checkbox
use constant S_NOKO        => 'Zur&uuml;ck zum';
use constant S_NOKOOFF     => 'Board';
use constant S_NOKOON      => 'Thread';
use constant S_CAPTCHA     => 'Captcha';       # Describes captcha field
use constant S_DELPASS     => 'Passwort';      # Describes password field
use constant S_DELEXPL     => '(Optional)';    # Prints explanation for password box (to the right)
use constant S_ALLOWED => 'Erlaubte Dateiformate (Maximalgr&ouml;&szlig;e %s oder angegeben)';

# if post form not shown in locked threads
use constant S_THREADLOCKED => '<strong>Thread %s</strong> ist geschlossen. Es kann nicht geantwortet werden.';

## thread / post header
use constant S_HIDE => 'Thread %d ausblenden';
use constant S_POSTNO  => 'Nr.';
use constant S_STICKYTITLE => 'Thread ist angepinnt'
  ;    # Defines the title of the tiny sticky image on a thread if it is sticky
use constant S_LOCKEDTITLE => 'Thread ist geschlossen'
  ;    # Defines the title of the tiny locked image on a thread if it is locked
use constant S_BUMPLIMIT => 'Systemkontra';
use constant S_REPLY   => 'Antworten';    # Prints text for reply link

# post files / tooltips
use constant S_FILEINFO => 'Informationen';
use constant S_FILENAME => 'Dateiname';
use constant S_FILEDELETED => 'Datei gel&ouml;scht';
use constant S_PICNAME => '';             # Prints text before upload name/link

## abbreviations on board page
use constant S_ABBR1 => '1 Post ';				# Prints text to be shown when replies are hidden
use constant S_ABBR2 => '%d Posts ';
use constant S_ABBRIMG1 => 'und 1 Datei ';		# Prints text to be shown when replies and files are hidden
use constant S_ABBRIMG2 => 'und %d Dateien ';
use constant S_ABBR_END => 'ausgeblendet';

use constant S_ABBRTEXT1 => '1 weitere Zeile anzeigen';
use constant S_ABBRTEXT2 => '%d weitere Zeilen anzeigen';

use constant S_BANNED  => '(User wurde f&uuml;r diesen Post gesperrt)';

## catalog strings
use constant S_REPLIES => 'Antworten: ';
use constant S_FILES => 'Dateien: ';
use constant S_PAGE => 'Seite: ';

## bottom page navigation
use constant S_PREV   => 'Zur&uuml;ck';    # Defines previous button
use constant S_NEXT   => 'Vor';            # Defines next button
use constant S_TOP    => 'Nach oben';
use constant S_BOTTOM => 'Nach unten';
use constant S_CATALOG => 'Katalog';
use constant S_RETURN => 'Zur&uuml;ck'; # Returns from thread back to image board

## bottom page delete form
use constant S_DELKEY => 'Passwort';    # Prints text next to password field for deletion (left)
use constant S_DELETE => 'L&ouml;schen';    # Defines deletion button's name


# javascript message strings (mask single quotes with \\\')
use constant S_JS_REMOVEFILE => 'Datei entfernen';
use constant S_JS_PLEASEWAIT => 'Bitte warten &hellip;';
use constant S_JS_SHOWTHREAD1 => 'Thread ';
use constant S_JS_SHOWTHREAD2 => ' einblenden';
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
use constant S_BANNEDIP => 'Deine IP-Adresse';
use constant S_BANNEDNET => 'Netz';

use constant S_BANNEDREASON => 'wurde mit folgender Begr&uuml;ndung gesperrt:';
use constant S_BANNEDNOREASON => 'wurde gesperrt.';

use constant S_BANNEDEXPIRE => 'Diese Sperrung l&auml;uft am <strong>%s</strong> ab.';
use constant S_BANNEDNOEXPIRE => 'Diese Sperrung gilt f&uuml;r unbestimmte Zeit.';

use constant S_BANNEDCONTACT => 'Bitte kontaktiere uns im IRC, wenn du wieder posten willst!';


## date strings
use constant S_WEEKDAYS => 'So Mo Di Mi Do Fr Sa'
  ;                                         # Defines abbreviated weekday names.
use constant S_MONTHS => 'Januar Februar M&auml;rz April Mai Juni Juli August September Oktober November Dezember'
  ;                                         # Defines long month names


## admin / management strings

# admin login page
use constant S_STAFFUSER => 'Benutzer';
use constant S_STAFFPASS => 'Passwort';
use constant S_ADMINPASS => 'Passwort:';    # Prints login prompt
use constant S_MANASAVE  => 'Speichern';    # Defines Label for the login cookie checbox
use constant S_MANALOGIN => 'Anmelden'
  ; # Defines Management Panel radio button--allows the user to view the management panel (overview of all posts)

# admin pages links / headings
use constant S_MANAPANEL => 'Posts moderieren'
  ; # Defines Management Panel radio button--allows the user to view the management panel (overview of all posts)
use constant S_MANABANS   => 'Sperren verwalten';         # Defines Bans Panel button
use constant S_MANATOOLS  => 'Werkzeuge';
use constant S_MANAORPH   => 'Verwaiste Dateien';
use constant S_MANALOG    => 'Log anzeigen';
use constant S_MANASTAFF  => 'Benutzer verwalten';
use constant S_MANAPASS   => 'Passwort &auml;ndern';
use constant S_MANALOGOUT => 'Abmelden';          #

use constant S_MANAMODE => 'Administration';   # Prints heading on top of Manager page
use constant S_MANARET => 'Zur&uuml;ck'
  ;    # Returns to HTML file instead of PHP--thus no log/SQLDB update occurs
use constant S_BOARD   => 'Board';

# admin tools page
use constant S_MANAGEOINFO => 'GeoIP-Informationen';
use constant S_MANADELETE => 'Posts l&ouml;schen';
use constant S_MPDELETEIP => 'Alle l&ouml;schen';
use constant S_DELALLMSG => 'Betroffen';
use constant S_DELALLCOUNT => '%d Posts (%d Threads)';
use constant S_IMGSPACEUSAGE => '[ Belegter Speicherplatz: %s, %d Dateien, %d Posts (%d Threads) ]'
  ;          # Prints space used KB by the board under Management Panel
use constant S_POSTSTATS => '[ &Auml;ltester Post: %s (Nr. %d), neuester Post: %s (Nr. %d) ]';

# admin orphans
use constant S_ORPHTABLE  => '<th>&Ouml;ffnen</th><th>Datei</th><th>&Auml;nderungsdatum</th><th>Gr&ouml;&szlig;e</th>';
use constant S_MANASHOW   => '&Ouml;ffnen';
use constant S_MPARCHIVE  => 'Archiv';

# admin log
use constant S_LOGTABLE => '<th>Datum</th><th>Ereignis</th><th>Benutzer</th><th>Post</th><th>IP</th><th>Kommentar (Ausschnitt)</th>';
use constant S_LOGFILTERON => 'Letzte 100 Eintr&auml;ge anzeigen';
use constant S_LOGFILTEROFF => 'Alle Eintr&auml;ge anzeigen';
use constant S_LOGCOMMENTSSHOW => 'Vollst&auml;ndige Kommentare anzeigen';
use constant S_LOGCOMMENTSHIDE => 'Vollst&auml;ndige Kommentare ausblenden';

# admin staff accounts
use constant S_ACCOUNTTABLE => '<th>Typ</th><th>Name</th><th>Status</th><th>Passwort</th><th>Zuletzt aktiv</th><th>Aktion</th>';
use constant S_ACCOUNTNEW => 'Benutzer hinzuf&uuml;gen';
use constant S_ACCOUNTTYPE => 'Typ';
use constant S_ACCOUNTADMIN => 'Admin';
use constant S_ACCOUNTMOD => 'Mod';
use constant S_ACCOUNTENABLED => 'Aktiv';
use constant S_ACCOUNTDISABLED => 'Deaktiviert';
use constant S_ACCOUNTENABLE => '(aktivieren)';
use constant S_ACCOUNTDISABLE => '(deaktivieren)';
use constant S_ACCOUNTPASS => '&Auml;ndern';
use constant S_ACCOUNTREMOVE => 'L&ouml;schen';
use constant S_ACCOUNTEXISTS => 'Benutzer existiert bereits.';

# staff change password
use constant S_PASSOLD  => 'Aktuelles Passwort';
use constant S_PASSNEW1 => 'Neues Passwort';
use constant S_PASSNEW2 => 'Passwort best&auml;tigen';
use constant S_PWCHANGEERR1 => 'Fehler: Neues Passwort und Best&auml;tigung stimmten nicht &uuml;berein.';
use constant S_PWCHANGEERR2 => 'Fehler: Aktuelles Passwort falsch.';
use constant S_PWCHANGEFAIL => 'Passwort nicht ge&auml;ndert.';
use constant S_PWCHANGEOK   => 'Passwort von Benutzer <i>%s</i> erfolgreich ge&auml;ndert.';

# post edit heading
use constant S_NOTAGS => 'Formatierung nur mit HTML-Tags. Keine Parser-Verarbeitung.'
  ;               # Prints message on Management Board
use constant S_SUBMIT     => 'Abschicken';     # Describes submit button

# admin post options
use constant S_POSTASADMIN => 'Administrationskennung am Post anzeigen';
use constant S_NOTAGS2 => 'Kommentar nicht durch den Parser verarbeiten';

# admin board page tooltip
use constant S_POSTINFO => 'IP-Informationen'; # admin post info tooltip heading

## admin post buttons
# thread buttons
use constant S_MPSTICKY    => 'Sticky setzen';
use constant S_MPUNSTICKY  => 'Sticky entfernen';
use constant S_MPLOCK      => 'Thread schlie&szlig;en';
use constant S_MPUNLOCK    => 'Thread &ouml;ffnen';
use constant S_MPSETSAGE   => 'Setze Systemkontra';
use constant S_MPUNSETSAGE => 'L&ouml;se Systemkontra';

use constant S_MPEDIT      => 'Kommentar bearbeiten';
use constant S_MPBAN       => 'Bann';
use constant S_MPDELETEALL => 'Alle Posts dieser IP l&ouml;schen';
use constant S_MPDELFILE   => 'Datei(en) l&ouml;schen';
use constant S_MPDELETE    => 'Post l&ouml;schen';    # Defines for deletion button in Management Panel


## admin ban page

# top forms
# ban form / jquery ban dialog
use constant S_BANIPLABEL      => 'IP-Adresse';
use constant S_BANMASKLABEL    => 'Netzmaske';
use constant S_BANDURATION     => 'Dauer';
use constant S_BANREASONLABEL  => 'Grund';
use constant S_BANINTERNALCOMMENTLABEL => 'Notiz';
use constant S_BANGLOBAL       => 'Auf allen Boards';
use constant S_BANFLAGPOST     => 'Post als gesperrt markieren';
use constant S_BANIP           => 'IP sperren'; # ip ban submit
use constant S_BANADDED        => 'Sperre hinzugefügt'; # json response
use constant S_BANFOUND        => 'User ist bereits gesperrt'; # json response

use constant S_BANCOMMENTLABEL => 'Kommentar';
use constant S_BANWHITELIST    => 'Whitelist'; # ip whitlist submit
use constant S_BANWORDLABEL    => 'Wort';
use constant S_BANWORD         => 'Wort abweisen'; # submit
use constant S_BANTRUSTTRIP    => 'Tripcode';
use constant S_BANTRUST        => 'Kein Captcha'; # trip whitelist submit
use constant S_BANASNUMLABEL   => 'AS-Nummer';
use constant S_BANASNUM        => 'Netz sperren'; # ban asn submit
use constant S_BANWRDFLTLABEL  => 'Suchfilter';
use constant S_BANWRDREPLABEL  => 'Ersetzen durch';
use constant S_BANWRDFLTADD    => 'Filter hinzuf&uuml;gen'; # word filter submit

# bans table bottom
use constant S_BANFILTER => 'Abgelaufene Sperren ausblenden';
use constant S_BANSHOWALL => 'Abgelaufene Sperren anzeigen';
use constant S_BANTABLE =>
  '<th>Typ</th><th colspan="2">Wert</th><th>Kommentar / Sperrgrund</th><th>Notiz</th><th>Board</th><th>Erstelldatum</th><th>Ablaufdatum</th><th>Ersteller</th><th>Aktion</th>'
  ;          # Explains names for Ban Panel
use constant S_BANREMOVE       => 'Entfernen';

# admin error messages
use constant S_WRDFLTINVALID => 'Wortfilter zu kurz oder zu lang oder enthält ungültige Zeichen.';


## error messages
# show page errors
use constant S_ERRORTITLE   => 'Fehler aufgetreten';
use constant S_INVALID_PAGE => "Fehler: Keine solche Seite gefunden.";
use constant S_STOP_FOOLING => "Lass das sein, Kevin!";
use constant S_NOTHREADERR  => 'Fehler: Der Thread existiert nicht.'
  ;    # Returns error when a non-existant thread is accessed
use constant S_NOREC =>
  'Fehler: Post nicht gefunden.'; # Returns error when record cannot be found
# posting errors
use constant S_LOCKED    => 'Thread ist geschlossen.';
use constant S_BADDELIP  => 'Fehler: Falsche IP-Adresse zum Löschen.'
  ;    # Returns error for wrong ip (when user tries to delete file)
use constant S_BADDELPASS => 'Fehler: Falsches L&ouml;schpasswort.'
  ;    # Returns error for wrong password (when user tries to delete file)

use constant S_TOOBIG       => 'Die Datei ist zu gro&szlig;.';
use constant S_TOOBIGORNONE => 'Die Datei ist zu gro&szlig; oder leer.';
use constant S_BADFORMAT => 'Fehler: Dateityp oder -format wird nicht unterst&uuml;tzt.'
  ;    # Returns error when the file is not in a supported format.

use constant S_NOCAPTCHA => 'Fehler: Kein CAPTCHA in der DB für diesen Key.'
  ;    # Returns error when there's no captcha in the database for this IP/key
use constant S_BADCAPTCHA =>
  'Fehler: Falscher Captcha-Code.';    # Returns error when the captcha is wrong

use constant S_STRREF =>
  'Fehler: String abgewiesen.';    # Returns error when a string is refused
use constant S_UNJUST => 'Fehler: Flood detektiert.'
  ; # Returns error on an unjust POST - prevents floodbots or ways not using POST method?
use constant S_NOPIC => 'Fehler: Keine Datei ausgew&auml;hlt.'
  ;    # Returns error for no file selected and override unchecked
use constant S_NOTEXT => 'Fehler: Keinen Text eingegeben.'
  ;    # Returns error for no text entered in to subject/comment
use constant S_TOOLONG1 => 'Fehler: Zu viele Zeichen im Feld Name, Betreff oder E-Mail.';
use constant S_TOOLONG2 => 'Fehler: Kommentar zu lang.'
  ;    # Returns error for too many characters in a given field
use constant S_NOTALLOWED1 =>
  'Fehler: Neue Threads m&uuml;ssen eine Datei enthalten.';    # Returns error for non-allowed post types
use constant S_NOTALLOWED2 =>
  'Fehler: Neue Threads d&uuml;rfen keine Dateien enthalten.';
use constant S_NOTALLOWED3 =>
  'Fehler: Antworten m&uuml;ssen eine Datei enthalten.';
use constant S_NOTALLOWED4 =>
  'Fehler: Antworten d&uuml;rfen keine Dateien enthalten.';
use constant S_UNUSUAL => 'Fehler: WAS GEHT DENN MIT DIR AB?'
  ;    # Returns error for abnormal reply? (this is a mystery!)

use constant S_BADHOST => 'Fehler: IP-Adresse ist gesperrt.'
  ;    # Returns error for banned host ($badip string)
use constant S_BADHOSTPROXY => 'Fehler: Proxy ist gesperrt.'
  ;    # Returns error for banned proxy ($badip string)
use constant S_ASBAN => 'AS-Netz-Sperre';
use constant S_AUTOBAN => 'Spambot [Auto Ban]'; # Ban reason for automatically created bans
use constant S_RENZOKU =>
  'Fehler: Zu viele Posts abgesetzt.';    # Returns error for $sec/post spam filter
use constant S_RENZOKU2 =>
  'Fehler: Zu viele Posts abgesetzt.';    # Returns error for $sec/upload spam filter
use constant S_RENZOKU3 =>
  'Fehler: Zu viele Posts abgesetzt.';    # Returns error for $sec/similar posts spam filter.
use constant S_RENZOKU4 =>
  'Fehler: L&ouml;schwartezeit noch nicht abgelaufen.';    # Returns error for too early post deletion.
use constant S_RENZOKU5 =>
  'Fehler: Zu viele Threads erstellt. Vor dem Erstellen neuer Threads bitte warten.';    # Returns error for too many threads spam filter.

use constant S_DUPE =>
  'Fehler: Die Datei wurde bereits <a href="%s">hier</a> hochgeladen.'
  ;    # Returns error when an md5 checksum already exists.
use constant S_DUPENAME =>
  'Fehler: Eine Datei desselbigen Namens existiert bereits.'
  ;    # Returns error when an filename already exists.

use constant S_WRONGPASS => 'Fehler: Falsches Passwort / Bitte erneut anmelden.'
  ;    # Returns error for wrong password (when trying to access Manager modes)
use constant S_BADSESSION => 'Fehler: Sitzung ung&uuml;ltig. Bitte erneut anmelden.';	# Returns error for wrong session ID (when trying to access Manager modes)
use constant S_BADACCOUNT => 'Fehler: Konto deaktiviert';					# Returns error for disabled account (when trying to access Manager modes)
use constant S_NOPRIV => 'Fehler: Keine Berechtigung';						# Returns error when mod tries to access or execute admin functions.

use constant S_NOTWRITE =>
  'Fehler: Verzeichnis konnte nicht beschrieben werden.'
  ; # Returns error when the script cannot write to the directory, the chmod (777) is wrong
use constant S_SPAM => 'Spam? Raus hier!';   # Returns error when detecting spam

use constant S_SQLCONF => 'MySQL-Datenbankfehler'; # Database connection failure
use constant S_SQLFAIL => 'MySQL-Datenbankfehler'; # SQL Failure


use constant TOOLTIP_TAGS => (
	LC_1Page => '1 Seite',
	LC_Pages => '%d Seiten',
	LC_1File => '1 Datei',
	LC_Files => '%d Dateien',
	LC_Archive => '<strong>Archiv mit %s:</strong>',
	LC_Omitted => '<em>(%d weitere nicht angezeigt)</em>',
	LC_Codec => 'Codec',

	"FileSize" => "Dateigr&ouml;&szlig;e",
	"FileType" => "Dateityp",
	"ImageSize" => "Aufl&ouml;sung",
	"ModifyDate" => "&Auml;nderungsdatum",
	"Comment" => "Kommentar",
	"Comment-xxx" => "Kommentar (2)",
	"CreatorTool" => "Erstellungstool",
	"Software" => "Software",
	"MIMEType" => "Inhaltstyp",
	"Producer" => "Software",
	"Creator" => "Generator",
	"Author" => "Autor",
	"Subject" => "Betreff",
	"PDFVersion" => "PDF-Version",
	"PageCount" => "Seiten",
	"Title" => "Titel",
	"Duration" => "L&auml;nge",
	"Artist" => "Interpret",
	"AudioBitrate" => "Bitrate",
	"ChannelMode" => "Kanalmodus",
	"Compression" => "Kompressionsverfahren",
	"FrameCount" => "Frames",
	"Vendor" => "Library-Hersteller",
	"Album" => "Album",
	"Genre" => "Genre",
	"Composer" => "Komponist",
	"Model" => "Modell",
	"Maker" => "Hersteller",
	"OwnerName" => "Besitzer",
	"CanonModelID" => "Canon-eigene Modellnummer",
	"UserComment" => "Kommentar (3)",
	"GPSPosition" => "Position",
	"Publisher" => "Herausgeber",
	"Language" => "Sprache",
	"AudioChannels" => "Audio-Kan&auml;le",
	"Channels" => "Kan&auml;le",
	"VideoFrameRate" => "Bildrate",
);


1;
