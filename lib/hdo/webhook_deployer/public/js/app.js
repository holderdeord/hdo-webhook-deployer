$(document).ready(function() {
  $('*[data-host]').each(function() {
    var el = $(this);

    $.ajax({
      url: "http://" + el.data('host') + '/info/revision',
      type: "GET",

      success: function(sha) {
        el.html('<a href="https://github.com/holderdeord/hdo-site/commits/' + sha + '">' + sha + "</a>");

        $.ajax({
          url: "https://api.github.com/repos/holderdeord/hdo-site/git/commits/" + sha + "?callback=",
          type: "GET",
          dataType: "jsonp",

          success: function(commit) {
            el.append('<p>' + commit.data.message + '(' + commit.data.author.name + ')</p>');
          }
        });

      }
    });
  })
});