function formatNum(str){
var newStr = "";
var count = 0;

while(str[0] == "0"){
  str = str.substring(1);
}

if(str.indexOf(".")==-1){
   for(var i=str.length-1;i>=0;i--){
 if(count % 3 == 0 && count != 0){
   newStr = str.charAt(i) + "," + newStr;
 }else{
   newStr = str.charAt(i) + newStr;
 }
 count++;
   }
   str = newStr + ".00";
}
else
{
   for(var i = str.indexOf(".")-1;i>=0;i--){
 if(count % 3 == 0 && count != 0){
   newStr = str.charAt(i) + "," + newStr;
 }else{
   newStr = str.charAt(i) + newStr;
 }
 count++;
   }
   str = newStr + (str + "00").substr((str + "00").indexOf("."),3);
 }
   return str
}
