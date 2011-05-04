$(document).ready(function() {

  $("tr:odd").addClass("odd");

  $('#flash a.closer').click(function() {
      $('#flash').animate({ height: 0, opacity: 0, marginTop: "-10px", marginBottom: "-10px" }, 'slow');
      $('#flash a.closer').hide();
      return false;
  });

  $('.datepicker').datepicker({
      showOn: "button",
      buttonImage: "../stylesheets/images/calendar.png",
      buttonImageOnly: true,
      dateFormat: 'yy-mm-dd' 
  });

  $('th.rotate-270').each(function() {
    var innerSpan = $(this).find('span').get(0);

    var width = null;
    if(typeof innerSpan !== 'undefined' && innerSpan !== null) {
      width = $(innerSpan).width();
    }
    if(width !== null) {
      $(this).css('height', width);
    }

    var height = null;
    if(typeof innerSpan !== 'undefined' && innerSpan !== null) {
      height = $(innerSpan).height();
    }
    if(height !== null) {
      $(this).css('width', height);
    }
  });
    
});
