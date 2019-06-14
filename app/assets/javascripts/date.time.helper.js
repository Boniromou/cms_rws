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

function getDateTimeStr(time_zone) {
  var now = getLocalTime(time_zone);
  return getDateStr(now) + ' ' + getTimeStr(now);
}

function getLocalTime(i) {

  if (typeof i !== 'number') return;
  var d = new Date();
  var len = d.getTime();
  var offset = d.getTimezoneOffset() * 60000;
  var utcTime = len + offset;

  return new Date(utcTime + 3600000 * i);

}
