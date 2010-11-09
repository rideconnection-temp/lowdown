class Customer < ActiveRecord::Base
  has_one :primary_address, :class_name => "Address", :foreign_key => "address_id"
  has_and_belongs_to_many :trips
  
  # validations
  validates_presence_of :routematch_customer_id
  validates_uniqueness_of :routematch_customer_id
end
