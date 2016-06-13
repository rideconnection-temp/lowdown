class Address < ActiveRecord::Base
  #has_many :customers
  has_many :trips

  def address
    "#{address_1} #{address_2}".strip
  end

  def full_address
    return "#{address} #{city} #{state} #{postal_code}"
  end

  def display_name
    return common_name || full_address
  end
end
