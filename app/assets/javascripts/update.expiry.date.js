  function updateExpiryDate(element, dateTime){
    element.html("Expiry: " + dateTime);
  }

  function onOptionChange(value){
    element = $('label#credit_expired_at');
    var now = new Date();
    var expire_date = new Date(now.getTime() + 24*60*60*1000*value);
    var date_str = getDateStr(expire_date) + ' ' + getTimeStrWithoutSecond(expire_date);
    updateExpiryDate(element, date_str);
  }
  $('select#duration').attr("onchange","onOptionChange(value)");
