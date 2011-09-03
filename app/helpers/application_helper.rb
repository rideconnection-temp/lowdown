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
