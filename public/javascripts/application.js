$(document).ready(function() {

  $("tr:odd").addClass("odd");

  $('#flash a.closer').click(function() {
      $('#flash').slideUp(150);
      return false;
  });

  //$(".monthpicker").monthpicker("1995-12", monthcallback);    
  function monthcallback(data,$e){
  	$e.next('input.monthtarget').val(data['year'] + '-' + zeroPad(data['month']));
  }

  function zeroPad(value) {
      return (parseInt(value, 10) < 10) ? ("0" + value.toString()) : value;
  }

  $( "#query_start_date, #query_end_date, #query_period_start, #query_period_end, #startday, #endday, #summary_period_start, #summary_period_end, #summary_report_prepared, .datepicker" ).datepicker({
      showOn: "button",
      buttonImage: "../images/calendar.png",
      buttonImageOnly: true,
      dateFormat: 'yy-mm-dd' 
  });

  $( "#query_provider, #query_allocation, #report-category, #group-by, #trip_allocation_id, #summary_provider_id, #summary_allocation_id" ).selectmenu();
  $("select.multi").multiselect();
  $('#trip_guest_count, #trip_attendant_count, #summary_total_miles, #summary_driver_hours_paid, #summary_driver_hours_volunteer, #summary_escort_hours_volunteer, #summary_administrative_hours_volunteer, #summary_unduplicated_riders, #summary_compliments, #summary_complaints, #summary_summary_rows_attributes_0_in_district_trips, #summary_summary_rows_attributes_0_out_of_district_trips, #summary_summary_rows_attributes_1_in_district_trips, #summary_summary_rows_attributes_1_out_of_district_trips, #summary_summary_rows_attributes_2_in_district_trips, #summary_summary_rows_attributes_2_out_of_district_trips, #summary_summary_rows_attributes_3_in_district_trips, #summary_summary_rows_attributes_3_out_of_district_trips, #summary_summary_rows_attributes_4_in_district_trips, #summary_summary_rows_attributes_4_out_of_district_trips, #summary_summary_rows_attributes_5_in_district_trips, #summary_summary_rows_attributes_5_out_of_district_trips, #summary_summary_rows_attributes_6_in_district_trips, #summary_summary_rows_attributes_6_out_of_district_trips, #summary_summary_rows_attributes_7_in_district_trips, #summary_summary_rows_attributes_7_out_of_district_trips, #run_odometer_start, #run_odometer_end, #run_escort_count').spinner({ min: 0, increment: 'fast' });

  $('input#file-import').change(function( objEvent ){$('.fakebrowseinput').val($(this).val());});

  $('.toggler').click(function() {
      $(this).next('.togglee').slideToggle();
      ($(this).hasClass('expand')) ? $(this).removeClass('expand').addClass('collapse') : $(this).removeClass('collapse').addClass('expand');
      return false;
  });    

  $('.toggler .select-all').click(function() {
      $(this).parent().next('.togglee').find('input[type=checkbox]').attr('checked', true);
      return false;
  });

  $('.togglee .unselect-all').click(function() {
      $(this).parent().find('input[type=checkbox]').attr('checked', false);
      return false;
  });

  function addGroupBy(element) {
    $('<div class="group-by-wrap"><select id="group-by-1"><option value="County">County</option><option value="Funding Source">Funding Source</option>option value="Project Name">Project Name</option><option value="Provider">Provider</option></select> <a class="remove-group-by" href="#"><img src="../images/spirit20/system-stop.png" alt="-" title="Remove this grouping criteria" /></a> <a class="add-group-by" href="#"><img src="../images/spirit20/system-save-alt-02.png" alt="+"  title="Add another group by field" /></a></div>').appendTo($(element).parent());
    renumberGroupBy();
  }

  function renumberGroupBy() {
    $('.group-by-wrap select').each(function(_, result) {
        $(result).attr("id", "group-by-" + (_ + 1));
        $( result).selectmenu();
    });
    $( ".group-by-wrap .add-group-by" ).unbind().click(function() {addGroupBy(this); return false;});
    $( ".group-by-wrap .remove-group-by" ).unbind().click(function() {$(this).parent().remove(); return false;});
  }

  renumberGroupBy();

});
