class Run < ActiveRecord::Base

  def display_name
    return name if name
    return "unnamed run #{id} on #{date}"
  end
end
