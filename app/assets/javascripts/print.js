function printHtml(html, landscape, title) {
  var printFrame = document.createElement('iframe');

  printFrame.name = "printFrame";
  printFrame.style.position = "absolute";
  printFrame.style.top = "-1000000px";
  document.body.appendChild(printFrame);

  var frameDoc = printFrame.contentWindow ? printFrame.contentWindow : printFrame.contentDocument.document ? printFrame.contentDocument.document : printFrame.contentDocument;
  frameDoc.document.open();
  frameDoc.document.write('<html><head><title>');
  frameDoc.document.write(title);
  frameDoc.document.write('</title>');
  if ( typeof landscape !== 'undefined' && landscape )
    frameDoc.document.write('<style>@media print{@page {size: landscape}}</style>'); //only work on Chrome
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
