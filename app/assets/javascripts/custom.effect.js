function slideDownUpdate(element, newdata) {
  widget = $(element);

  reshowWidget = function(widget) {
    setTimeout(function() {
      widget.html(newdata);
      widget.removeAttr( "style" ).hide();
      widget.show("slide", { direction: "up" }, 500);
    }, 1000);
  }

  widget.hide("slide", { direction: "down" }, 500, reshowWidget(widget))
}

function animateUpdate(element, newdata) {
  var widget = $(element);
  var animatingClass = 'animating';
  widget.addClass(animatingClass);

  function setIntervalX(callback, delay, repetitions, afterCallback) {
    var repeated = 0;
    var intervalID = window.setInterval(function() {
      callback();

      if ( ++repeated === repetitions ) {
        window.clearInterval(intervalID);

        window.setTimeout(afterCallback, 500);
      }
    }, delay);
  }

  var flashInterval = 1000;
  var flashTime = 3;

  setIntervalX(function() {
                 $(element).effect("highlight", {color: '#FFFFA3'}, flashInterval);
               },
               flashInterval,
               flashTime,
               function() {
                 slideDownUpdate(element, newdata);
               });

  setTimeout(function() {
    widget.removeClass(animatingClass);
  }, flashTime * flashInterval + 2000);
}
