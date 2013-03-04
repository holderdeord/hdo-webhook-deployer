$(document).ready(function() {
  $('*[data-host]').each(function() {
    $.ajax({
      url: "http://" + $(this).data('host') + '/info/revision',
      type: "GET",

      success: function(text) {
        $(this).html('<a href="https://github.com/holderdeord/hdo-site/commits/' + text + '">' + text + "</a>");
      },
    });
  })
});