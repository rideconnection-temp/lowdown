module ApplicationHelper

  def gmaps_address_link(address, klass)
    escaped_address = URI.escape address.full_address 
    
    "<a class=\"#{klass}\" href=\"http://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&q=#{escaped_address}&sll=#{address.y_coordinate},#{address.x_coordinate}&sspn=0.008708,0.017896&ie=UTF8&hq=&hnear=#{escaped_address}&t=h&z=16\" title=\"#{address.full_address}\">#{address.display_name}</a>"
  end

  def flash_messages
    if flash[:notice]
      "<div id=\"flash\">
         <a class=\"closer\" href=\"#\">Close</a>
         <div class=\"info\">#{flash[:notice]}</div>   
      </div>"
    else
      ''
    end
  end

  def nested_size_with_totals(e)
    if e.instance_of? Hash
      total = 1
      for k, v in e
        total += nested_size_with_totals v
      end
      return total
    else
      return 1
    end
  end

  def get_row(e)
      if e.instance_of? Hash
        get_row e.first[1]
      else
        e
      end
  end
  
end
