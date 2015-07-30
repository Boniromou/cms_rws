  $('#pop_up_dialog #cancel').click(function() {
    $('#pop_up_dialog').removeClass("fadeIn");
    $('#pop_up_dialog').addClass("fadeOut");
    setTimeout(function(){
    $('#pop_up_dialog').css("display", "none");
    },600);
    return false;
  });

  function registerPopUpPanel(form_id, content){
    $('#pop_up_content').html(content);
    $('#pop_up_dialog').css("display", "block");
    $('#pop_up_dialog').removeClass("fadeOut");
    $('#pop_up_dialog').addClass("fadeIn");
    $('#pop_up_dialog #confirm').focus();
  
    $('#pop_up_dialog #confirm').click(function() {
      $(form_id).submit();
      return false;
    });

  }

