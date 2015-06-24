  $(document).ready(function() {
    $('input[autofocus="autofocus"]').focus();
  });

  function formValidated(form_id, formComps, lengthLimit) {
    function validated(comp, index) {

      if ( comp.val() == "" )
        return false;

      if ( lengthLimit[index] > 0 && comp.val().length != lengthLimit[index] )
        return false;

      return true;
    }

    function targetLabel(index) {
      return $("form#"+ form_id +" > fieldset > div.row:eq(" + index + ") > div.col:eq(2) label");
    }

    function showError(comp, index) {
      targetLabel(index).css('visibility', 'visible');
      comp.parent().addClass('state-error');
    }

    function hideError(comp, index) {
      targetLabel(index).css('visibility', 'hidden');
      comp.parent().removeClass('state-error');
    }

    var allValidated = true;

    for (var i = 0; i < formComps.length; i++) {
      var comp = $(formComps[i]);

      if ( !validated(comp, i) ) {
        allValidated = false;

        showError(comp, i);
      }
      else {
        hideError(comp, i);
      }
    }

    return allValidated;
  }
