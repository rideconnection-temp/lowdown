module ApplicationHelper

  def gmaps_address_link(address, klass)
    escaped_address = URI.escape address.full_address 
    
    "<a class=\"#{klass}\" href=\"http://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&q=#{escaped_address}&sll=#{address.y_coordinate},#{address.x_coordinate}&sspn=0.008708,0.017896&ie=UTF8&hq=&hnear=#{escaped_address}&t=h&z=16\" title=\"#{address.full_address}\">#{address.display_name}</a>"
  end

  def gmaps_route_link(start_address,end_address, klass)
    escaped_start_address = URI.escape start_address.full_address 
    escaped_end_address = URI.escape end_address.full_address 
    "<a class=\"#{klass}\" href=\"http://maps.google.com/maps?saddr=#{escaped_start_address}&daddr=#{escaped_end_address}\">Route</a>"
  end

  def flash_type(type)
   if flash[type]
      "<div id=\"flash\">
         <a class=\"closer\" href=\"#\">Close</a>
         <div class=\"info\">#{flash[type]}</div>   
      </div>"
    else
      ''
    end
  end

  def flash_messages
    return flash_type(:notice) + flash_type(:alert)
  end
  
  def report_month_range(start_date, after_end_date)
    end_date = after_end_date - 1.month
    if start_date.year == end_date.year && start_date.month == end_date.month
      start_date.strftime("%B %Y")
    else
      "#{start_date.strftime("%B %Y")} through #{end_date.strftime("%B %Y")}"
    end
  end
  
  def row_sort(k)
    if k.blank?
      [2, ""]
    elsif k.class == Fixnum
      [1, ("%04d" % k)]
    else
      [1, k.to_s.downcase]
    end
  end

  def quarterly_report_funding_sources(reporting_agency_id,program_id,county)
    return if program_id.blank? || reporting_agency_id.blank? || county.blank?
    a = Allocation.where(:program_id => program_id,:reporting_agency_id => reporting_agency_id,:county => county)
    a.map{|x| x.project.try(:funding_source).try(:name) }.compact.sort.uniq.join(", ")
  end

  def group_by_label(value)
    value.map { |field| FlexReport::GroupMappings[field] || field.titlecase }.join(", ")
  end

  def group_by_option_tag(value)
    fields     = group_by_label(value.split(","))
    attributes = { :value => value }
    attributes[:selected] = "selected" if @report.group_by == value
    
    content_tag :option, fields, attributes
  end
  
  def checked?(field)
    "checked" if @report.new_record? || @report.field_list.split(",").include?(field)
  end

  def bodytag_class
    a = controller.class.to_s.underscore.gsub(/_controller$/, '')
    b = controller.action_name.underscore
    "#{a} #{b}".gsub(/_/, '-')
  end

  def describe_date_range(start_date,end_date)
    if start_date == end_date
      result = start_date.strftime('%A %B %e %Y')
    elsif start_date.day == 1 and (end_date + 1.day).day == 1
      if start_date + 1.month == end_date + 1.day # One calendar month
        result = start_date.strftime('Month of %B, %Y')
      elsif start_date + 3.months == end_date + 1.day && (start_date.month - 1).modulo(3) == 0 # A quarter
        quarter = (start_date.month - 1) / 3 + 1
        fiscal_quarter = quarter < 3 ? quarter + 2 : quarter - 2
        result = "#{start_date.strftime('%B')} to #{end_date.strftime('%B')}, #{end_date.year}"
        result += " (#{fiscal_quarter.ordinalize} Quarter of Fiscal Year #{describe_fiscal_year start_date})"
      elsif start_date + 12.months == end_date + 1.day && start_date.month == 7 # Full fiscal year
        result = "#{start_date.strftime('%B')} #{start_date.year} to #{end_date.strftime('%B')} #{end_date.year} (Fiscal Year #{describe_fiscal_year start_date})"
      elsif start_date + 12.months == end_date + 1.day && start_date.month == 1 # Full calendar year
        result = "Calendar Year #{start_date.year}"
      elsif start_date.year == end_date.year # Full months, all in the same calendar year
        result = "#{start_date.strftime('%B')} to #{end_date.strftime('%B')}, #{end_date.year}"
      else # Full months, traversing calendar years
        result = "#{start_date.strftime('%B')} #{start_date.year} to #{end_date.strftime('%B')} #{end_date.year}"
      end
    elsif start_date.month == end_date.month && start_date.year == end_date.year # Both dates in same month
      result = "#{start_date.strftime('%B %e')} to #{end_date.strftime('%e, %Y')}"
    elsif start_date.year == end_date.year # Both dates in same year
      result = "#{start_date.strftime('%B %e')} to #{end_date.strftime('%B %e, %Y')}"
    else #Everything else
      result = "#{start_date.strftime('%B %e %Y')} to #{end_date.strftime('%B %e %Y')}"
    end
    result
  end

  def describe_fiscal_year(date)
    date += 1.year if date.month > 6 
    "#{date.year-1}-#{date.strftime('%y')}"
  end

  def service_end_date(date)
    return date if date.blank? || !date.acts_like?(:date)
    if date.day < 16
      Date.new(date.year, date.month, 15)
    else
      d = date + 1.month
      Date.new(d.year, d.month, 1) - 1.day   
    end
  end

  def seconds_to_hours_colon_minutes_colon_seconds(seconds_in)
    return nil if seconds_in.nil?
    hours_out   = (seconds_in / 3600).to_i
    minutes_out = ((seconds_in - (hours_out * 3600)) / 60).to_i
    seconds_out = (seconds_in - (hours_out * 3600) - (minutes_out * 60))
    "%02d:%02d:%02d" % [hours_out,minutes_out,seconds_out]
  end

  def address_fields(address)
    [address.common_name, address.building_name, address.address_1, address.address_2, address.city, address.state, address.postal_code]
  end

  def mark_if_changed(record,attribute)
    return if record.previous.nil?
    return if record.send(attribute).blank? && record.previous.send(attribute).blank?
    ' class="changed"'.html_safe if record.send(attribute) != record.previous.send(attribute)
  end

  def mark_if_summary_row_changed(row,attribute)
    return if row.summary.nil? || row.summary.previous.nil?
    previous_row = row.summary.previous.summary_rows.detect{|prev| prev.purpose == row.purpose }
    return if row.send(attribute).blank? && previous_row.send(attribute).blank?
    ' class="changed"'.html_safe if row.send(attribute) != previous_row.send(attribute)
  end

  def summary_attribute_change(record,attribute)
    return if record.previous.nil?
    change = (record.send(attribute) || 0) - (record.previous.send(attribute) || 0)
    return if change == 0
    "<div class=\"change\">#{change}</div>".html_safe
  end

  def summary_row_attribute_change(row,attribute)
    return '<td></td>'.html_safe if row.summary.nil? || row.summary.previous.nil?
    previous_row = row.summary.previous.summary_rows.detect{|prev| prev.purpose == row.purpose }
    change = (row.send(attribute) || 0) - (previous_row.send(attribute) || 0)
    return '<td></td>'.html_safe if change == 0
    "<td class=\"change\">#{change}</td>".html_safe
  end

  def attribute_difference(record, attribute)
    return if record.previous.nil?
    change = (record.send(attribute) || 0) - (record.previous.send(attribute) || 0)
    change == 0 ? nil : change
  end

  def row_trip_link(report,row)
    trip_allocations = (Allocation.trip_collection_method.map{|a| a.id} & row.allocations.map{|a| a.id}).sort
    if trip_allocations != []
      start_date = (row.start_date || report.start_date)
      end_date   = (row.after_end_date || report.after_end_date) - 1.day
      link_to "Trips", {:controller => :trips, :action => :list, 
          :q => {:allocation_id_list => "#{trip_allocations.join(' ')}", 
          :start_date => start_date, :end_date => end_date}}
    end
  end

  def row_summary_link(report, row)
    summary_allocations = (Allocation.summary_collection_method.map{|a| a.id} & row.allocations.map{|a| a.id}).sort
    if summary_allocations != []
      start_date = (row.start_date || report.start_date)
      end_date   = (row.after_end_date || report.after_end_date) - 1.day
      link_to "Summaries", {:controller => :summaries, 
          :q => {:allocation_id_list => "#{summary_allocations.join(' ')}", 
          :start_date => start_date, :end_date => end_date}}
    end
  end
end
