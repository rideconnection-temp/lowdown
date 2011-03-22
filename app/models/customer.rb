class Customer < ActiveRecord::Base
  belongs_to :primary_address, :class_name => "Address", :foreign_key => "address_id"
  #has_one :primary_address, :class_name => "Address", :foreign_key => "address_id"
  has_many :trips
  
  # validations
  validates_presence_of :routematch_customer_id
  validates_uniqueness_of :routematch_customer_id

  def name
    return "#{last_name}, #{first_name} #{middle_initial}"
  end
end
