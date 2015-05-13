function blockEnter(event){ 
  if (event.keyCode == 13) {
    $('div#button_set button#confirm').click();
    return false;
  }
}


$('form#fund_request').keydown(blockEnter);
