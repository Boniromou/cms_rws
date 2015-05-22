CARD_ID_LENGTH_LIMIT = 20;
MEMBER_ID_LENGTH_LIMIT = 8;

function validateNumberOnly(element, value) {
  var numericRegexp = /^\d+/;

  $(element).val(numericRegexp.exec($(element).val()));

  return false;
}

function validateMaxLength(element, value, length) {
  if ( length >= 0 ) {
    $(element).val($(element).val().substring(0, length));
  }

  return false;
}

function validateNumberOnlyAndMaxLength(element, value, length) {
  validateNumberOnly(element, value);
  validateMaxLength(element, value, length);

  return false;
}

function ValidateFloat(e, pnumber)
{
  if (pnumber[0] == "0"){
    if(pnumber[1] == "0"){
      while(pnumber[0] == "0"  && pnumber[1] == "0"){
        pnumber = pnumber.substring(1);
      }
    }else if (pnumber.length >1 && pnumber[1] != "."){
      pnumber = pnumber.substring(1);
    }
    $(e).val(pnumber);
  }
  if (!/^\d{1,7}([.](\d\d?)?)?$/.test(pnumber)){
    result = /^\d{1,7}([.](\d\d?)?)?/.exec(pnumber);
    if(result == null)
      $(e).val("");
    else
      $(e).val(result[0]);
  }
  return false;
}
