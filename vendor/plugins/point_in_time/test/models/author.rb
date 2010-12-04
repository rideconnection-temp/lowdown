class Author < ActiveRecord::Base
  point_in_time
  def create_new_version?
    first_name_change && last_name_changed? 
  end
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def hello_world(n=1)
    "Hello World #{n}"
  end
  
end
