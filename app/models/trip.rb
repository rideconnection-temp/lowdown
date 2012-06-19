class Trip < ActiveRecord::Base
  require 'bigdecimal'
  extend ActiveSupport::Memoizable

  class << self
    def date_range(start_date, after_end_date)
      start_date = start_date.to_date
      after_end_date = after_end_date.to_date
      where("trips.date >= ? AND trips.date < ?",start_date,after_end_date)
    end
  end

  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by
  point_in_time
  belongs_to :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  belongs_to :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  belongs_to :home_address, :class_name => "Address", :foreign_key => "home_address_id"
  belongs_to :allocation
  belongs_to :run, :primary_key=>"base_id"
  belongs_to :customer
  belongs_to :trip_import

  after_validation :set_duration_and_mileage
  after_save :apportion_shared_rides
  after_create :apportion_new_run_based_trips

  attr_protected :apportioned_fare, :apportioned_mileage, :apportioned_duration
  attr_protected :mileage, :duration

  attr_accessor :bulk_import, :secondary_update, :do_not_version

  scope :completed, where(:result_code => 'COMP')
  scope :data_entry_complete, where(:complete => true)
  scope :data_entry_not_complete, where(:complete => false)
  scope :shared, where('trips.routematch_share_id IS NOT NULL')
  scope :spd, joins(:allocation=>:project).where(:projects => {:funding_source => 'SPD'})
  scope :for_allocation, lambda {|allocation| where(:allocation_id => allocation.id) }
  scope :for_allocation_id, lambda {|allocation_id| where(:allocation_id => allocation_id) }
  scope :for_provider, lambda {|provider_id| where("trips.allocation_id IN (SELECT id FROM allocations WHERE provider_id = ?)",provider_id)}
  scope :for_subcontractor, lambda {|subcontractor| where("trips.allocation_id IN (SELECT id FROM allocations WHERE provider_id IN (SELECT id FROM providers where subcontractor = ?))",subcontractor)}
  scope :for_date_range, lambda {|start_date,after_end_date| where("date >= ? AND date < ?",start_date,after_end_date) }
  scope :without_no_shows, where("trips.result_code <> ?","NS")
  scope :without_cancels, where("trips.result_code <> ?","CANC")
  scope :for_customer_first_name_like, lambda {|name| where("trips.customer_id IN (SELECT id FROM customers WHERE LOWER(first_name) LIKE ?)","%#{name.downcase}%") }
  scope :for_customer_last_name_like, lambda {|name| where("trips.customer_id IN (SELECT id FROM customers WHERE LOWER(last_name) LIKE ?)","%#{name.downcase}%") }
  scope :for_import, lambda {|import_id| where(:trip_import_id=>import_id)}

  RESULT_CODES = {'Completed' => 'COMP','Turned Down' => 'TD','No Show' => 'NS','Unmet Need' => 'UNMET','Cancelled' => 'CANC'}

  def created_by
    return first_version.updated_by
  end

  def completed?
    result_code == 'COMP'
  end

  def shared?
    routematch_share_id.present?
  end
  
  def updated_by_user
    return (self.updated_by.nil? ? User.find(:first) : User.find(self.updated_by)) #right now, imports run through the command line will have no user info
  end

  def customers_served
    guest_count + attendant_count + 1
  end
  
  def chronological_versions
    return self.versions.sort{|t1,t2|t1.updated_at <=> t2.updated_at}.reverse
  end

  def wheelchair?
    if mobility == "Ambulatory" 
      false
    elsif mobility.nil?
      nil
    else
      true
    end
  end 

  def spd_mileage
    if self.estimated_trip_distance_in_miles < 5
      return 0
    elsif self.estimated_trip_distance_in_miles < 25
      return self.estimated_trip_distance_in_miles - 5
    else
      return 20
    end
  end

  memoize :customers_served

  def create_revision_with_known_attributes_without_callbacks(attrs)
    old_version = versions.build self.attributes.merge( attrs )

    old_version.valid_end = now_rounded
    old_version.should_run_callbacks = false
    old_version.save!(:validate=>false)
  end

private

  def create_new_version?
    !do_not_version?
  end
  
  def do_not_version?
    do_not_version == true || do_not_version.to_i == 1 || !complete || !complete_was
  end

  def set_duration_and_mileage
    unless secondary_update 
      if completed? && (allocation.run_collection_method == 'trips')
        self.duration = (end_at - start_at).to_i unless end_at.nil? || start_at.nil?
        if odometer_end.nil? || odometer_start.nil? || odometer_start == 0
          if bpa_billing_distance
            self.mileage = bpa_billing_distance
          elsif odometer_start == 0 && (odometer_end || 0) > 0
            self.mileage = odometer_end - odometer_start 
          end 
        else
          self.mileage = odometer_end - odometer_start 
        end
        if routematch_share_id.blank?
          self.apportioned_fare = fare unless fare.nil?
          self.apportioned_duration = duration unless duration.nil?
          self.apportioned_mileage = mileage unless mileage.nil?
        end
      end
    end
  end

  def apportion_shared_rides
    unless secondary_update || bulk_import
      return if should_run_callbacks == false

      # currently shared, update new routematch_share rides
      reapportion_trips_for_routematch_share_id( routematch_share_id ) if shared? 

      if routematch_share_id_changed?
        # previously shared, update old routematch_share rides
        reapportion_trips_for_routematch_share_id( routematch_share_id_change.first ) if routematch_share_id_change.first.present?
      end
    end
    return true
  end
  
  def reapportion_trips_for_routematch_share_id(rms_id)
    r = Trip.current_versions.completed.where(:routematch_share_id=>rms_id, :date=>date).order(:end_at,:created_at).all
    trip_count    = r.size
    ride_duration = (r.map(&:end_at).max - r.map(&:start_at).min).to_i
    ride_mileage  = r.map(&:odometer_end).max - r.map(&:odometer_start).min
    ride_cost     = r.sum(&:fare)
    all_est_miles = r.sum(&:estimated_trip_distance_in_miles)
    has_rate_data = !r.map(&:estimated_individual_fare).include?(nil) 
    if has_rate_data
      all_estimated_individual_fares = r.sum(&:estimated_individual_fare)
    end

    # Keep a tally of apportionments made so any remainder can be applied to the last trip.
    ride_duration_remaining = ride_duration
    ride_mileage_remaining = ride_mileage
    ride_cost_remaining = ride_cost
        
    trip_position = 0

    for t in r
      trip_position += 1
      # Avoid infinite recursion
      t.secondary_update = true

      this_mileage_ratio = t.estimated_trip_distance_in_miles / all_est_miles

      this_trip_duration = (ride_duration.to_f * this_mileage_ratio).floor
      ride_duration_remaining = (ride_duration_remaining - this_trip_duration)
      t.apportioned_duration = this_trip_duration + ( trip_position == trip_count ? ride_duration_remaining : 0 )

      this_trip_mileage = (ride_mileage * this_mileage_ratio * 100).floor.to_f / 100 
      ride_mileage_remaining = (ride_mileage_remaining - this_trip_mileage).round(2)
      t.apportioned_mileage = this_trip_mileage + ( trip_position == trip_count ? ride_mileage_remaining : 0 )

      if has_rate_data 
        this_fare_ratio = t.estimated_individual_fare / all_estimated_individual_fares
        this_trip_cost = (ride_cost * this_fare_ratio * 100).floor.to_f / 100
      else
        this_trip_cost = (ride_cost * this_mileage_ratio * 100).floor.to_f / 100
      end
      ride_cost_remaining = (ride_cost_remaining - this_trip_cost).round(2)
      t.apportioned_fare = this_trip_cost + ( trip_position == trip_count ? ride_cost_remaining : 0 )
      t.do_not_version = true
      t.save!
    end
  end

  def apportion_new_run_based_trips
    if !should_run_callbacks
      return true
    end
    unless secondary_update || bulk_import
      self.run.save!
    end
  end
end
