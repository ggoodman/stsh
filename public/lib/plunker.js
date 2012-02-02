(function() {

  $(function() {
    return jQuery.getJSON("http://stsh.ggoodman.c9.io/api/v1/plunks", function(json) {
      var $a, $caption, $img, $li, plunk, _i, _len;
      for (_i = 0, _len = json.length; _i < _len; _i++) {
        plunk = json[_i];
        $li = $("<li></li>").addClass("span3");
        $a = $("<a></a>").attr("href", plunk.url).addClass("thumbnail").appendTo($li);
        $img = $("<img />").attr("src", "http://placehold.it/205x154&text=Loading...").attr("data-original", "http://immediatenet.com/t/l3?Size=1024x768&URL=" + plunk.url).attr("alt", plunk.description || ("Plunk: " + plunk.id)).addClass("lazy").appendTo($a);
        $caption = $("<div><h5>Plunk " + plunk.id + "</h5><p>" + (plunk.description || 'Untitled') + "</p></div>").addClass("caption").appendTo($a);
        $li.appendTo("#recent");
      }
      return $("img.lazy").lazyload({
        threshold: 200,
        effect: "fadeIn"
      });
    });
  });

}).call(this);
