class Address < ActiveRecord::Base
  #has_many :customers
  has_many :trips

  def full_address
    return address_1 + " " + address_2 + " " + city + " " + state + " " + postal_code
   end
end
