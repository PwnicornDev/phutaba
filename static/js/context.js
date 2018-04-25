function highlight() {
  // dummy
  // to be here until the board doesn't hardcode it into posts anymore
}

(function () {
var postCache, preview = (function () {
  var previewBox = $j('<div id=preview>')
    , status = []
  ;

  function loadPost(num, board, callback) {
    $j.get('/wakaba.pl?task=show&board=' + encodeURIComponent(board) + '&post=' + num,
      function (data) {
        var post;
        try {
          post = $j(data.trim());
        } catch(error) {
          post = $j('<div id="' + num + '"><div class="post_head post">' + data.trim() + '</div></div>');
        }
        post.attr('id', board+num);
        if (!exists(board+num)) {
          postCache.append(post);
        }
        callback(post);
      });
  }

  function showPost(p, pos) {
    previewBox.empty()
      .append( p.hasClass('thread_OP') ?
        clonePost(p.attr('id')) :
        p.find('.post').clone() )
      .css({left: pos.X + 5 + 'px', top: pos.Y - p.outerHeight()/2 + 'px'})
      .show()
      .appendTo(document.body);
  }

  return {
    show : function (num, board, pos, callback) {
      var p = exists('#c' + num) ? $j('#c' + num) :
          exists(board+num) ? $j('#' + board+num) :
          board !== window.board ? undefined :
          exists(+num) ? $j('#' + num) :
          undefined
        , isVisible = p && p.offset().top + p.outerHeight() > window.scrollY &&
          window.scrollY + $j(window).height() > p.offset().top
        , isEntirelyVisible = p && p.offset().top > window.scrollY &&
          window.scrollY + $j(window).height() > p.offset().top + p.outerHeight()
      ;

      if (p) {
        if (!isEntirelyVisible) {
          showPost(p, pos);
        }
        if (isVisible) {
          p.addClass('highlight');
        }
        callback();
      } else {
        if (!status[board+num]) {
          loadPost(num, board, function (post) {
            if (status[board+num] !== "aborted") {
              showPost(post, pos, previewBox);
              callback();
              status[board+num] = "loaded";
            }
          });
        }
        status[board+num] = "loading";
      }
    },

    hide : function (num, board) {
      var posts = $j('#' + num + ',#c' + num);
      status[board+num] = "aborted";
      previewBox.hide().empty();
      posts.removeClass('highlight');
    }
  };
})();

function clonePost (id) {
  var post = $j('#' + id).clone();
  post.attr('id', 'c' + id);
  post.find('span.backreflink a').attr('href', function (i, href) {
    return href.replace('#', '#c');
  });
  return post
}

function getTarget (a) {
  return (a.attr ? a.attr('href') : a.getAttribute('href')).match(/\d+/g).pop();
}

function getBoard (a) {
  return (a.attr ? a.attr('href') : a.getAttribute('href')).match(/\/([\wäöü]+)\/thread\//).pop();
}

function exists (query) {
  //return !!(typeof query === 'number' ? document.getElementById(query) : $j(query).length);
  return !!(document.getElementById(query));
}

$j(document).ready(function () {
  postCache = $j('<div id=post_cache>').appendTo($j('body'));

  $j('body').on('mouseenter', 'span.backreflink a', function (ev) {
    var el = $j(ev.target)
      , pos = el.offset()
    ;
    el.css({cursor: 'progress'});
    preview.show(getTarget(ev.target),
      getBoard(ev.target),
      {X: pos.left + el.outerWidth(), Y: pos.top + el.outerHeight()/2},
      function () { el.css({cursor: ''}); });
  });

  $j('body').on('mouseleave', 'span.backreflink a', function (ev) {
    var el = $j(ev.target);
    el.css({cursor: ''});
    preview.hide(getTarget(el), getBoard(el));
  });
});
})();
