/* requires jquery: $j = jQuery.noConflict(); */

/* called when loading a board-page: read list of hidden threads from the cookie and hide them */
function hideThreads(bid) {
	hidThreads = loadThreads(bid);
	for (i = 0; i < hidThreads.length; i++) {
		thread = $j('thread_' + hidThreads[i]);
		if (thread == null)
			continue;
		$j("#thread_" + hidThreads[i]).hide();
		$j("#thread_" + hidThreads[i]).after(getHiddenHTML(hidThreads[i], bid));
	}
}

/* hides a single thread from the board page and adds HTML to display it again */
function hideThread(tid, bid) {
	hidThreads = loadThreads(bid);
	for (i = 0; i < hidThreads.length; i++)
		if (hidThreads[i] == tid)
			return;
	$j("#thread_" + tid).hide();
	$j("#thread_" + tid).after(getHiddenHTML(tid, bid));
	addHideThread(tid, bid);
};

/* displays the thread again after it was hidden */
function showThread(tid, bid) {
	$j('.show_' + tid).hide();
	$j('.show_' + tid).remove();
	$j("#thread_" + tid).show();
	removeHideThread(tid, bid);
};

/** internal helper functions **/

/* adds the thread id to the cookie */
function addHideThread(tid, bid) {
	hidThreads = loadThreads(bid);
	for (i = 0; i < hidThreads.length; i++)
		if (hidThreads[i] == tid)
			return;
	hidThreads[hidThreads.length] = tid;
	saveThreads(bid, hidThreads);
}

/* deletes a thread id from the cookie */
function removeHideThread(tid, bid) {
	hidThreads = loadThreads(bid);
	if (hidThreads.length == 0)
		return;
	for (i = 0; i < hidThreads.length; i++)
		if (hidThreads[i] == tid) {
			hidThreads.splice(i, 1);
			i--;
		}
	saveThreads(bid, hidThreads);
}

/* load thread list from cookie */
function loadThreads(bid) {
	value = $j.cookie('hidden_' + bid);
	if (value == null)
		return [];
	return JSON.parse(value);
}

/* save thread list to cookie */
function saveThreads(bid, threads) {
	$j.cookie('hidden_' + bid, JSON.stringify(threads), { expires: 7, path: '/'+bid+'/' });
}

/* create HTML for diplaying a hidden thread */
function getHiddenHTML(tid, bid) {
	return '<div class="show_' + tid + ' togglethread">'
		+ '<a class="hide" onclick="showThread(\'' + tid + '\', \'' + bid + '\');">'
		+ '<img src="/img/icons/show.png" width="16" height="16" alt="'
		+ msg_show_thread1 + tid + msg_show_thread2 + '" />'
		+ ' <strong>' + msg_show_thread1 + tid + '</strong>'
		+ msg_show_thread2 + '</a></div>';
};

