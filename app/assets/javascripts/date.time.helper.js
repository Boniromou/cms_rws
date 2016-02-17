function addZero(digit) {
  var str = digit;

  if ( digit < 10 )
    str = "0" + str;

  return str;
}

function getDateStr(now) {
  return now.getFullYear() + '-' + addZero(now.getMonth() + 1) + '-' + addZero(now.getDate());
}

function getTimeStr(now) {
  return addZero(now.getHours()) + ':' + addZero(now.getMinutes()) + ':' + addZero(now.getSeconds());
}

function getTimeStrWithoutSecond(now) {
  return addZero(now.getHours()) + ':' + addZero(now.getMinutes());
}

function getDateTimeStr() {
  var now = new Date();
  return getDateStr(now) + ' ' + getTimeStr(now);
}
