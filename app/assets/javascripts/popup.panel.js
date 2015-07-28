  $('#pop_up_dialog #cancel').click(function() {
    $('#pop_up_dialog').css("display", "none");

    return false;
  });

  function registerPopUpPanel(form_id, content){
    $('#pop_up_content').html(content);
    $('#pop_up_dialog').css("display", "block");
    $('#pop_up_dialog #confirm').focus();
  
    $('#pop_up_dialog #confirm').click(function() {
      $(form_id).submit();
      return false;
    });

  }

