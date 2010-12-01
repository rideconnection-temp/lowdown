class Trip < ActiveRecord::Base
  belongs_to :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  belongs_to :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  #has_one :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  #has_one :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  has_one :customer

  attendent_count
  guest_count

  odo_start, odo_end 
  total_miles = max(odo_end) - min(odo_start) group by share_id
  estimated_miles
  apportioned_miles

  apportioned_fare
  fare
  share_id
end
