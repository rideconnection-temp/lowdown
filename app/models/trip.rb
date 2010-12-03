class Trip < ActiveRecord::Base
  point_in_time
  belongs_to :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  belongs_to :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  has_one :customer
end
