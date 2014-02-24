/**
 * jQuery.fn.sortElements
 * --------------
 * @author James Padolsey (http://james.padolsey.com)
 * @version 0.11
 * @updated 18-MAR-2010
 * --------------
 * @param Function comparator:
 *   Exactly the same behaviour as [1,2,3].sort(comparator)
 *   
 * @param Function getSortable
 *   A function that should return the element that is
 *   to be sorted. The comparator will run on the
 *   current collection, but you may want the actual
 *   resulting sort to occur on a parent or another
 *   associated element.
 *   
 *   E.g. $('td').sortElements(comparator, function(){
 *      return this.parentNode; 
 *   })
 *   
 *   The <td>'s parent (<tr>) will be sorted instead
 *   of the <td> itself.
 */
jQuery.fn.sortElements = (function(){
    
    var sort = [].sort;
    
    return function(comparator, getSortable) {
        
        getSortable = getSortable || function(){return this;};
        
        var placements = this.map(function(){
            
            var sortElement = getSortable.call(this),
                parentNode = sortElement.parentNode,
                
                // Since the element itself will change position, we have
                // to have some way of storing it's original position in
                // the DOM. The easiest way is to have a 'flag' node:
                nextSibling = parentNode.insertBefore(
                    document.createTextNode(''),
                    sortElement.nextSibling
                );
            
            return function() {
                
                if (parentNode === this) {
                    throw new Error(
                        "You can't sort elements if any one is a descendant of another."
                    );
                }
                
                // Insert before flag:
                parentNode.insertBefore(this, nextSibling);
                // Remove flag:
                parentNode.removeChild(nextSibling);
                
            };
            
        });
       
        return sort.call(this, comparator).each(function(i){
            placements[i].call(getSortable.call(this));
        });
        
    };
    
})();

$(document).ready(function() {
  function htmlEncode(value){
    //create a in-memory div, set it's inner text(which jQuery automatically encodes)
    //then grab the encoded contents back out.  The div never exists on the page.
    return $('<div/>').text(value).html();
  }

  function htmlDecode(value){
    return $('<div/>').html(value).text();
  }

  if ($("#page-header h1").html() != null) {
    document.title = htmlDecode($("#page-header h1").html());
  }

  function setAllocationSummaryGroupBy(){
    var listItems = $("ul#sortable-selected li");
    var listArray = [];
    listItems.each(function(index) {
      listArray.push($(this).data()["group"]);
    });
    $("#report_query_group_by").val(listArray.join());
  }

  setAllocationSummaryGroupBy();

  $( "ul#sortable-selected, ul#sortable-unselected" ).sortable({
    connectWith: ".connectedSortable",
    stop: function(){
      setAllocationSummaryGroupBy();
    }
  }).disableSelection();

  $('a#unselect-all').click(function() {
    $("ul#sortable-selected li").appendTo("ul#sortable-unselected")
    $("ul#sortable-unselected li").sortElements(function(a, b) {
      return $(a).text() > $(b).text() ? 1 : -1;
    });
    setAllocationSummaryGroupBy();
  });

  $("tr:odd").addClass("odd");

  $('#flash a.closer').click(function() {
      $('#flash').animate({ height: 0, opacity: 0, marginTop: "-10px", marginBottom: "-10px" }, 'slow');
      $('#flash a.closer').hide();
      return false;
  });

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

  // format report headers
  $('th.wrap').each(function(index, element) {
    var th = $(element), word_array, last_word, first_part;
    word_array = th.html().split(/\s+/); // split on spaces
    th.html(word_array.join('<br />')); // join 'em back together with line breaks
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

  // Hide the date fields if the user selects all dates
  $('#q_all_dates').change(function() {
    if($('#q_all_dates').attr("checked")) {
      $('#date_fields').slideUp();
    } else {
      $('#date_fields').slideDown();
    }
  });
  
  // Hide the transfer count field if the user selects all trips
  $('#transfer_all').change(function() {
    if($('#transfer_all').attr("checked")) {
      $('#transfer_count').slideUp();
    } else {
      $('#transfer_count').slideDown();
    }
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

  // Make flex report rows collapsible
  $('.collapsible').click(function() {
    var t = $(this);
    t.toggleClass('hidden-group');
    t.toggleClass('visible-group');
    resetFlexReportRowVisibility();
  });

  $('#collapse-all').click(function() {
    // Make all groups hidden
    $('.visible-group').toggleClass('hidden-group').toggleClass('visible-group');
    // No go back and make the root group visible so the first level of groups are shown.
    // (Per user user request, this is actually 'collapse all but first group level')
    $('.level-0.hidden-group').toggleClass('hidden-group').toggleClass('visible-group');
    resetFlexReportRowVisibility();
    return false;
  });

  $('#expand-all').click(function() {
    $('.hidden-group').toggleClass('hidden-group').toggleClass('visible-group');
    resetFlexReportRowVisibility();
    return false;
  });

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

  $('#show-update-form').click(function() {
    $('.run-report').toggle('slow');
    return false;
  });

  $('#unselect-all-columns').click(function() {
    $('#report-checkbox-area input').attr('checked', false) 
    return false;
  });

  $('#select-all-columns').click(function() {
    $('#report-checkbox-area input').attr('checked', true) 
    return false;
  });

  $('.autosize').autosize({append: "\n"});

  // When moving trips in bulk from one allocation to another, only allow movement
  // within a provider
  function limitDestinationAllocationSelect() {
    if ($('#q_allocation').val() == '') {
      $('#q_dest_allocation').children().each(function(i,option) {
        $(option).hide();
      });
    } else {
      $('#q_dest_allocation').children().each(function(i,option) {
        if (
          $(option).val() == $('#q_allocation').val() || 
          $(option).data('provider-id') != $('#q_allocation option:selected').data('provider-id')
        ) {
          $(option).hide();
          if ($('#q_dest_allocation').val() == $(option).val()) {
            $('#q_dest_allocation').val('');
          }
        } else {
          $(option).show();
        }
      });
    }
  }
  limitDestinationAllocationSelect();
  $('#q_allocation').change(limitDestinationAllocationSelect);
});
