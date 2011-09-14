module ApplicationHelper

  def gmaps_address_link(address, klass)
    escaped_address = URI.escape address.full_address 
    
    "<a class=\"#{klass}\" href=\"http://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&q=#{escaped_address}&sll=#{address.y_coordinate},#{address.x_coordinate}&sspn=0.008708,0.017896&ie=UTF8&hq=&hnear=#{escaped_address}&t=h&z=16\" title=\"#{address.full_address}\">#{address.display_name}</a>"
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
  
  def report_month_range(start_date, end_date)
    end_date = end_date - 1.month
    if start_date.year == end_date.year && start_date.month == end_date.month
      start_date.strftime("%B %Y")
    else
      "#{start_date.strftime("%B %Y")} through #{end_date.strftime("%B %Y")}"
    end
  end
  
  def row_sort(k,v)
      k.blank? ? [2, ""] : [1, k.to_s]
  end

  def group_by_option_tag(value)
    mappings = {
      "funding_subsource" => "Funding Sub-source", 
      "project_number"    => "Project Code",
      "agency"            => "Provider"
    }
    
    fields     = value.split( "," ).map { |field| mappings[field] || field.titlecase }.join(", ")
    attributes = { :value => value }
    attributes[:selected] = "selected" if @report.group_by == value
    
    content_tag :option, fields, attributes
  end
  
  def checked?(field)
    "checked" if @report.new_record? || @report.field_list.split(",").include?(field)
  end

  def get_row(e)
      if e.instance_of? Hash
        get_row e.first[1]
      else
        e
      end
  end
  
  def bodytag_class
    a = controller.class.to_s.underscore.gsub(/_controller$/, '')
    b = controller.action_name.underscore
    "#{a} #{b}".gsub(/_/, '-')
  end

end
