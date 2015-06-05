function printHtml(html) {
  var printFrame = document.createElement('iframe');

  printFrame.name = "printFrame";
  printFrame.style.position = "absolute";
  printFrame.style.top = "-1000000px";
  document.body.appendChild(printFrame);

  var frameDoc = printFrame.contentWindow ? printFrame.contentWindow : printFrame.contentDocument.document ? printFrame.contentDocument.document : printFrame.contentDocument;
  frameDoc.document.open();
  frameDoc.document.write('<html><head><title>Contents</title>');
  frameDoc.document.write('</head><body>');
  frameDoc.document.write(html);
  frameDoc.document.write('</body></html>');
  frameDoc.document.close();

  setTimeout(function () {
      window.frames["printFrame"].focus();
      window.frames["printFrame"].print();
      document.body.removeChild(printFrame);
  }, 500);

  return false;
}
