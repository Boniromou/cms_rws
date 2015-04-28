function slideDownUpdate(element, newdata) {
  widget = $(element);

  reshowWidget = function(widget) {
    setTimeout(function() {
      widget.html(newdata);
      //widget.removeAttr( "style" ).hide().fadeIn();
      widget.removeAttr( "style" ).hide();
      widget.show("slide", { direction: "up" }, 500);
    }, 1000);
  }
  //widget.animate({ opacity: 0 }, 900, reshowWidget(widget));
  widget.hide("slide", { direction: "down" }, 500, reshowWidget(widget));
}
