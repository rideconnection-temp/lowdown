class Page < ActiveRecord::Base
  point_in_time
  
  belongs_to :author
  belongs_to :creator, :class_name=>'Author'
end
