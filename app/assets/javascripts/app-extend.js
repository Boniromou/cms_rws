//$.ajax({ cache: false });

//$('div#content').on('ajax:error', function(xhr, status, error) {
//  $(this).html(xhr.responseText);
//});

var troll = new Troll(function() {
  $('body').addClass("smart-style-3");
});

$(document).ajaxError(function (e, xhr, settings) {
  if (xhr.status == 401) {
    location.reload();
  }
});

$('nav').on('ajax:beforeSend', function(xhr, settings) {
  var container = $('div#content');
  container.removeData().html("");
  container.html('<h1 class="ajax-loading-animation"><i class="fa fa-cog fa-spin"></i> Loading...</h1>');
});

$(document).on('ajax:complete', function(xhr, status) {
  //console.log("hereeeeeeeeee");
  //console.log(xhr);
  //console.log(status);
  //console.log(xhr.delegateTarget.activeElement.href);
  //history.pushState(null, document.title, xhr.delegateTarget.activeElement.href);
});

//.not('form#search_form')
/*
$('div#content > form#search_form').on('ajax:beforeSend', function(xhr, settings) {
  var container = $('div#content');
  $(#audit_logs_result)
  container.removeData().html("");
  container.html('<h1 class="ajax-loading-animation"><i class="fa fa-cog fa-spin"></i> Loading...</h1>');
});
*/
window.paceOptions = {
  elements: false,
  restartOnRequestAfter: true
}

// Date Range Picker
$("#from").datepicker({
    defaultDate: "+1w",
    changeMonth: true,
    numberOfMonths: 1,
    prevText: '<i class="fa fa-chevron-left"></i>',
    nextText: '<i class="fa fa-chevron-right"></i>',
    onClose: function (selectedDate) {
        $("#to").datepicker("option", "minDate", selectedDate);
    }

});
$("#to").datepicker({
    defaultDate: "+1w",
    changeMonth: true,
    numberOfMonths: 1,
    prevText: '<i class="fa fa-chevron-left"></i>',
    nextText: '<i class="fa fa-chevron-right"></i>',
    onClose: function (selectedDate) {
        $("#from").datepicker("option", "maxDate", selectedDate);
    }
});
