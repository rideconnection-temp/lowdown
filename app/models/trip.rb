class Trip < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  #point_in_time
  belongs_to :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  belongs_to :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  belongs_to :provider
  belongs_to :run
  belongs_to :customer

  def customers_served
    if routematch_share_id
      return Trip.count(:conditions=>{:routematch_share_id=>routematch_share_id})
    else
      return 1
    end
  end

  memoize :customers_served

end
