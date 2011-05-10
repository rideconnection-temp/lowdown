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

  var ISODateFormatToDateObject = function(str) {
    if(str === null) {
        return null;
    }

    var parts = str.split(' ');
    if(parts.length < 2) {
      return null;
    }
    
    var dateParts = parts[0].split('-'),
    timeSubParts = parts[1].split(':'),
    timeSecParts = timeSubParts[2].split('.'),
    timeHours = Number(timeSubParts[0]);

    _date = new Date();
    _date.setFullYear(Number(dateParts[0]));
    _date.setMonth(Number(dateParts[1])-1);
    _date.setDate(Number(dateParts[2]));
    _date.setHours(Number(timeHours));
    _date.setMinutes(Number(timeSubParts[1]));
    _date.setSeconds(Number(timeSecParts[0]));
    if (timeSecParts[1]) {
        _date.setMilliseconds(Number(timeSecParts[1]));
    }

    return _date;
  };

  $('#query_start_date').change(function() {
    var pickupTimeDate = ISODateFormatToDateObject($('#query_start_date').attr("value"));
    var appointmentTimeDate = ISODateFormatToDateObject($('#query_end_date').attr("value"));
    var newPickupDate = new Date(pickupTimeDate.getTime() + (1000 * 60 * 30));    
    $('#query_end_date').attr( "value", newPickupDate.format("yyyy-mm-dd HH:MM:ss"));
  });


  // add time picker functionality
  // http://trentrichardson.com/examples/timepicker/
  $('.datetimepicker').datetimepicker({
  	ampm: false,
  	hourMin: 8,
  	hourMax: 18,
		hourGrid: 3,
  	minuteGrid: 15,
		timeFormat: 'hh:mm:ss',
		dateFormat: 'yy-mm-dd',
    showOn: "button",
    buttonImage: "/stylesheets/images/calendar-clock.png",
    buttonImageOnly: true,
    constrainInput: false
  });


  // format report headers
  $('th.wrap').each(function(index, element) {
    var th = $(element), word_array, last_word, first_part;
    word_array = th.html().split(/\s+/); // split on spaces
    th.html(word_array.join('<br />')); // join 'em back together with line breaks
  });
    
});
