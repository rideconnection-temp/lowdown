$(document).ready(function() {
  //*****************************************
  //
  // Application-wide 
  //
  //*****************************************

  // helper code for setting the h1 page header
  function htmlDecode(value){
    return $('<div/>').html(value).text();
  }
  // if the page has an h1 page header, make it the document title
  if ($("#page-header h1").html() != null) {
    document.title = htmlDecode($("#page-header h1").html());
  }

  // make text areas grow with additional text
  $('.autosize').autosize({append: "\n"});

  // Add zebra-striping of tables
  $("tr:odd").addClass("odd");

  // Make flash messages able to be dismissed
  $('#flash a.closer').click(function() {
      $('#flash').animate({ height: 0, opacity: 0, marginTop: "-10px", marginBottom: "-10px" }, 'slow');
      $('#flash a.closer').hide();
      return false;
  });

  // Make error messages, which have their details hidden (shrunk) by default, expandable
  $('#error_explanation a.shrinker').click(function() {
    var errDiv = $('#error_explanation');
    if (errDiv.hasClass('shrinkable')) {
      errDiv.removeClass('shrinkable').addClass('expandable');
    } else {
      errDiv.removeClass('expandable').addClass('shrinkable');
    }
  });

  // date picker
  $('.datepicker').datepicker({
    showOn: "button",
    buttonText: "Select",
    dateFormat: 'yy-mm-dd', 
    changeYear: true,
    showOtherMonths: true,
    selectOtherMonths: true
  });

  //*****************************************
  //
  // Summaries
  //
  //*****************************************

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

  //*****************************************
  //
  // Trips
  //
  //*****************************************

  // Hide the date fields if the user selects all dates
  if($('#q_all_dates').prop("checked")) {
    $('#date_fields').hide();
  } else {
    $('#date_fields').show();
  }
  $('#q_all_dates').change(function() {
    if($('#q_all_dates').prop("checked")) {
      $('#date_fields').slideUp();
    } else {
      $('#date_fields').slideDown();
    }
  });
  
  // In Move Trips, Hide the transfer count field if the user selects all trips
  $('#transfer_all').change(function() {
    if($('#transfer_all').prop("checked")) {
      $('#transfer_count').slideUp();
    } else {
      $('#transfer_count').slideDown();
    }
  });

  // When moving trips in bulk from one allocation to another, only allow movement
  // within a provider
  function limitDestinationAllocationSelect() {
    var sourceAllocation = $('#q_allocation_id');
    var selectedProvider = sourceAllocation.children(':selected').first().data('provider-id')
    var destinationAllocation = $('#q_dest_allocation_id');

    if (sourceAllocation.val() == '') {
      destinationAllocation.children().each(function(i,option) {
        $(option).hide();
      });
    } else {
      destinationAllocation.children().each(function(i,option) {
        if (
          $(option).data('provider-id') == selectedProvider &&
          $(option).val() != sourceAllocation.val()
        ) {
          $(option).show();
        } else {
          $(option).hide();
          if (destinationAllocation.val() == $(option).val()) {
            destinationAllocation.val('');
          }
        }
      });
    }
  }
  limitDestinationAllocationSelect();
  $('#q_allocation_id').change(limitDestinationAllocationSelect);

  //*****************************************
  //
  // Flex Report Form
  //
  //*****************************************
  
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

  // Make the list of selected filter items match the select list in 
  // flex report filters
  $("li.filter select").change(function() {
    var list = $(this).parent().find("ul.filter-list");
    $(this).find("option").each(function() {
      if($(this).is(":selected")) {
        list.find("[data-value='" + $(this).val() + "']").show();
      } else {
        list.find("[data-value='" + $(this).val() + "']").hide();
      }
    });
  });

  // Toggle visibility of flex report filters and lists
  $("li.filter h3").click(function() {
    $(this).parent().find("select").toggle();
    $(this).parent().find("ul").toggle();
  });
  $("li.filter ul").click(function() {
    $(this).parent().find("select").show();
    $(this).parent().find("ul").hide();
  });
  $("#expand-all-filters").click(function() {
    $("#filters select").show();
    $("#filters ul").hide();
    return false;
  });
  $("#collapse-all-filters").click(function() {
    $("#filters select").hide();
    $("#filters ul").show();
    return false;
  });

  // Select/unselect all column checkboxes in flex report form
  $('#unselect-all-columns').click(function() {
    $('#report-checkbox-area input').prop('checked', false) 
    return false;
  });
  $('#select-all-columns').click(function() {
    $('#report-checkbox-area input').prop('checked', true) 
    return false;
  });

  //*****************************************
  //
  // Flex Report Rendering
  //
  //*****************************************
  
  // Make flex report rows collapsible
  function resetFlexReportRowVisibility() {
    // Go through every row that could possibly be visible, and make it so
    $('.visible-group').each(function(i, row) {
      $('.' + $(row).data('group') + '.' + $(row).data('section')).show();
    });
    // Now go through every row that needs to be hidden, and make it so
    $('.hidden-group').each(function(i, row) {
      $('.' + $(row).data('group') + '.' + $(row).data('section')).hide();
    });
  }
  // When user clicks on a header, toggle the visiblity of the rows that serve as its children
  $('.collapsible').click(function() {
    var t = $(this);
    t.toggleClass('hidden-group');
    t.toggleClass('visible-group');
    resetFlexReportRowVisibility();
  });
  // Collapse all rows except for the first group level
  $('#collapse-all').click(function() {
    // Make all groups hidden
    $('.visible-group').toggleClass('hidden-group').toggleClass('visible-group');
    // No go back and make the root group visible so the first level of groups are shown.
    $('.level-0.hidden-group').toggleClass('hidden-group').toggleClass('visible-group');
    resetFlexReportRowVisibility();
    return false;
  });
  // Expand all rows
  $('#expand-all').click(function() {
    $('.hidden-group').toggleClass('hidden-group').toggleClass('visible-group');
    resetFlexReportRowVisibility();
    return false;
  });

  // toggle the visibility of the form that updates a flex report in-place 
  $('#show-update-form').click(function() {
    $('.run-report').toggle('slow');
    return false;
  });

  //*****************************************
  //
  // Predefined Reports
  //
  //*****************************************

  // Use placement drag-and-drop elements to update the hidden group_by field
  function setAllocationSummaryGroupBy(){
    var listItems = $("ul#sortable-selected li");
    var listArray = [];
    listItems.each(function(index) {
      listArray.push($(this).data()["group"]);
    });
    $("#report_query_group_by").val(listArray.join());
  }
  setAllocationSummaryGroupBy();

  // Enable drag-and-drop functionality
  $( "ul#sortable-selected, ul#sortable-unselected" ).sortable({
    connectWith: ".connectedSortable",
    stop: function(){
      setAllocationSummaryGroupBy();
    }
  }).disableSelection();

  // Add ability to move all drag-and-drop elements to the unselected area
  $('a#unselect-all').click(function() {
    $("ul#sortable-selected li").appendTo("ul#sortable-unselected")
    $("ul#sortable-unselected li").sortElements(function(a, b) {
      return $(a).text() > $(b).text() ? 1 : -1;
    });
    setAllocationSummaryGroupBy();
  });

});
