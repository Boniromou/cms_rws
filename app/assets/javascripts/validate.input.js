function validateNumberOnly(element, value) {
  var numericRegexp = /^\d+/;

  $(element).val(numericRegexp.exec($(element).val()));

  return false;
}

function ValidateFloat(e, pnumber)
{
  if (!/^\d{1,7}([.](\d\d?)?)?$/.test(pnumber)){
    result = /^\d{1,7}([.](\d\d?)?)?/.exec(pnumber);
    if(result == null)
      $(e).val("");
    else
      $(e).val(result[0]);
  }
  return false;
}
