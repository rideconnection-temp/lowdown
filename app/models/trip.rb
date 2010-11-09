class Trip < ActiveRecord::Base
  has_one :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  has_one :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  has_and_belongs_to_many :customers

  # validations
  validates_presence_of :pickup_address, :dropoff_address
end
