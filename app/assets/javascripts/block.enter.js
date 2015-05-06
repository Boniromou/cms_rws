function blockEnter(event){ 
  if (event.keyCode == 13) {
    $('button#confirm').focus();
    throw ""
    return false;
  }
}


$('form#fund_request').keydown(blockEnter);
