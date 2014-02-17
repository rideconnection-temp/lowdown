class Customer < ActiveRecord::Base
  belongs_to :primary_address, :class_name => "Address", :foreign_key => "address_id"
  has_many :trips, :order => "start_at DESC"
  
  accepts_nested_attributes_for :primary_address
  
  # validations
  validates_presence_of :routematch_customer_id
  validates_uniqueness_of :routematch_customer_id

  def name
    return "#{last_name}, #{first_name} #{middle_initial}"
  end
  
  def age_in_years(as_of = Date.today)
    return nil if birthdate.nil?
    years = as_of.year - birthdate.year #2011 - 1980 = 31
    if as_of.month < birthdate.month  || as_of.month == birthdate.month and as_of.day < birthdate.day #but 4/8 is before 7/3, so age is 30
      years -= 1
    end
    return years
  end
end
