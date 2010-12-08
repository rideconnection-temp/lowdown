class Run < ActiveRecord::Base
  has_many :trips

  def display_name
    return name if name
    return "unnamed run #{id} on #{date}"
  end
end
