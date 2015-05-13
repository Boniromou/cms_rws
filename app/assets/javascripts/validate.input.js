function validateNumberOnly(element, value) {
  var numericRegexp = /^\d+/;

  $(element).val(numericRegexp.exec($(element).val()));

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
