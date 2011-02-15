class Customer < ActiveRecord::Base
  belongs_to :primary_address, :class_name => "Address", :foreign_key => "address_id"
  #has_one :primary_address, :class_name => "Address", :foreign_key => "address_id"
  has_many :trips
  
  # validations
  validates_presence_of :routematch_customer_id
  validates_uniqueness_of :routematch_customer_id

  def name
    return "#{first_name} #{middle_initial} #{last_name}"
  end

  def approved_rides(start_date, end_date)
    return Trip.where("customer_id = ? and date between ? and ?", id, start_date, end_date).count
  end

  def billed_rides(start_date, end_date)
    #FiXME
    return Trip.where("customer_id = ? and date between ? and ?", id, start_date, end_date).count
  end

  def billable_mileage(start_date, end_date)
    #FIXME
    return Trip.where("customer_id = ? and date between ? and ?", id, start_date, end_date).sum("apportioned_mileage")
  end

end
