class Trip < ActiveRecord::Base
  require 'bigdecimal'
  extend ActiveSupport::Memoizable

  point_in_time
  belongs_to :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  belongs_to :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  belongs_to :allocation
  belongs_to :run
  belongs_to :customer

  after_validation :set_duration_and_mileage
  before_create :apportion_run_based_trips
  after_save :apportion_shared_rides

  attr_accessor :secondary_update

  def customers_served
    if routematch_share_id
      return Trip.count(:conditions=>{:routematch_share_id=>routematch_share_id})
    else
      return 1
    end
  end

  memoize :customers_served

private

def set_duration_and_mileage
  unless secondary_update
    self.duration = ((end_at - start_at) / 60 ).to_i unless end_at.nil? || start_at.nil?
    self.mileage = odometer_end - odometer_start unless odometer_end.nil? || odometer_start.nil?
    if routematch_share_id.blank?
      self.apportioned_fare = fare unless fare.nil?
      self.apportioned_duration = duration unless duration.nil?
      self.apportioned_mileage = mileage unless mileage.nil?
    end
  end
end

def apportion_run_based_trips
  unless secondary_update
    if self.allocation.run_collection_method == 'runs' 
      r = Trip.where(:run_id => run_id)
      trip_count = r.count + 1 # +1 to include this new trip
      ratio = 1 / trip_count.to_f
      run_duration = ((run.end_at - run.start_at) / 60).to_i
      run_mileage = run.odometer_end - run.odometer_start
      trip_duration = (run_duration * ratio).to_i
      trip_mileage = (run_mileage * ratio).round(1)

      run_duration_remaining = run_duration
      run_mileage_remaining = run_mileage

      trip_position = 0

      for t in r
        trip_position += 0
        t.seconday_update = true

        run_duration_remaining -= trip_duration 
        t.duration = trip_duration

        run_mileage_remaining -= trip_mileage
        t.mileage = trip_mileage
      end
      self.duration = trip_duration + run_duration_remaining
      self.mileage = trip_mileage + run_mileage_remaining.round(1)
    end
  end
end

def apportion_shared_rides
  unless secondary_update
    if routematch_share_id.present?
      r = Trip.where(:routematch_share_id => routematch_share_id).order(:end_at,:created_at)
#     All these aggregates are run separately.  
#     could be optimized into one query with a custom SELECT statement.
      trip_count   = r.count
      ride_duration = ((r.maximum(:end_at) - r.minimum(:start_at)) / 60).to_i
      ride_mileage  = r.maximum(:odometer_end) - r.minimum(:odometer_start)
      ride_cost     = r.sum(:fare)
      all_est_miles = r.sum(:estimated_trip_distance_in_miles)

#     Keep a tally of apportionments made so any remainder can be applied to the last trip.
      ride_duration_remaining = ride_duration
      ride_mileage_remaining = ride_mileage
      ride_cost_remaining = ride_cost

      trip_position = 0

      for t in r
        trip_position += 1
#       Avoid infinite recursion
        t.secondary_update = true
        this_ratio = t.estimated_trip_distance_in_miles/all_est_miles

        this_trip_duration = (ride_duration.to_f * this_ratio).to_i
        ride_duration_remaining -= this_trip_duration
        t.apportioned_duration = this_trip_duration + ( trip_position == trip_count ? ride_duration_remaining : 0 )

        this_trip_mileage = (ride_mileage.to_f * this_ratio).round(1)
        ride_mileage_remaining -= this_trip_mileage
        t.apportioned_mileage = this_trip_mileage + ( trip_position == trip_count ? ride_mileage_remaining.round(1) : 0 )

        this_trip_cost = (ride_cost * this_ratio).round(2)
        ride_cost_remaining -= this_trip_cost
        t.apportioned_fare = this_trip_cost + ( trip_position == trip_count ? ride_cost_remaining.round(2) : 0 )
        t.save
      end
    end
  end
end

end
