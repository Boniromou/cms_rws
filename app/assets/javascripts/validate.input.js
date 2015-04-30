function validateNumberOnly(element, value) {
  var numericRegexp = /^\d+/;

  $(element).val(numericRegexp.exec($(element).val()));

  return false;
}

function ValidateFloat(e, pnumber)
{
  if (!/^\d+[.]?[\d\d]?$/.test(pnumber))
  {
      $(e).val(/^\d+[.]?\d\d/.exec($(e).val()));
  }
  return false;
}
