$("*").on('ajax:beforeSend', function(event, xhr, settings) {
  xhr.setRequestHeader('TerminalID', getTerminalID());
});