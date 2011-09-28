$(document).ready(function() {

  $("tr:odd").addClass("odd");

  $('#flash a.closer').click(function() {
      $('#flash').animate({ height: 0, opacity: 0, marginTop: "-10px", marginBottom: "-10px" }, 'slow');
      $('#flash a.closer').hide();
      return false;
  });

  // date picker
  $('.datepicker').datepicker({
      showOn: "button",
      buttonText: "Select",
      dateFormat: 'yy-mm-dd', 
      changeYear : true
  });

  // format report headers
  $('th.wrap').each(function(index, element) {
    var th = $(element), word_array, last_word, first_part;
    word_array = th.html().split(/\s+/); // split on spaces
    th.html(word_array.join('<br />')); // join 'em back together with line breaks
  });

  // toggle adjustment range selects
  $("input:checkbox[name='report[adjustment]']").change(function(){
    $(this).parents("form").find("ol.adjustments").toggleClass("hidden");
  });

  // live totals on summary show-create
  $("body.summaries.show-create").find("input[data-district]").change(function(change){
    var district = $(this).data("district");
    var total    = 0;

    $.each( $("input[data-district=" + district + "]").map( function( index, input ){
      return parseInt($(this).val(), 10);
    }), function() {
        total += this;
    });

    $("#" + district + "_district_total").val( total );
  });
  
  $("#all-reports").sortable({
    handle : ".handle",
    stop : function(event, ui) {
      var order = {};

      ui.item.closest('ul').children('li').each(function(index) {
        order[ $(this).data("id") ] = index;
      });
      
      $.post("reports/sort", {reports : order});
    }
  });
  
  var options_buffer = [];
  // When trip index is filtered by provider, allocations list is filtered for that provider
  $("body.trips.list #trip_query_provider").change(function(event){
    while (options_buffer.length > 0){
      $("#trip_query_allocation").append( options_buffer.pop() );
    }
    
    var provider_id = parseInt( $(this).val() );
        
    $("#trip_query_allocation option").each(function(i, item){
      var this_provider_id = parseInt($(item).data("provider-id"));
      if ( this_provider_id && this_provider_id != provider_id ) {
        options_buffer.push( item );
        $(item).remove();
      }
    });    
  });

  // generates a new group by select value, given each of the custom field values
  var updateCustomOptionValue = function() {
    var realSelect = $("#group-by");

    var newRealSelectValue = "";
    var customSelectValues = $("#group-by-custom-wrapper").find("select");

    customSelectValues.each(function() {
	var value = $(this).find("option:selected").val();

	if(newRealSelectValue.length > 0) {
	  newRealSelectValue += ",";
	}
	newRealSelectValue += value;
    });

    realSelect.find("option:selected").val(newRealSelectValue);
  };

  // shows the custom grouping UI when the "custom" option is chosen
  $('#group-by').change(function() {
    var selectedLabel = $(this).find("option:selected").text();
    
    if(selectedLabel === "Define Custom Grouping...") {
	$("#group-by-custom-section").show();
	$("#group-by-custom-section").find("select").change(updateCustomOptionValue).trigger("change");
    } else {
	$("#group-by-custom-section").hide();
    }
  });
  $('#group-by').trigger("change");
    
  // duplicate the "template" span, and add a remove button to the new option item when user chooses to 
  // add new grouping field to the custom option
  $('#group-by-custom-section').find("a").click(function() {
    var wrapper = $("#group-by-custom-wrapper");
    var template = wrapper.find(".template");

    var newOption = template.clone();
    newOption.removeClass("template");

    // add remove link to new option span
    var newOptionRemoveLink = $('<a class="delete">Remove</a>').click(function() {
	$(this).parent().remove();
        updateCustomOptionValue();
    });

    newOption.append(newOptionRemoveLink);

    // bind new listener to select to update real select's value when this one is changed
    newOption.find("select").change(updateCustomOptionValue);

    wrapper.append(newOption);
    updateCustomOptionValue();

    return false;
  });

});
