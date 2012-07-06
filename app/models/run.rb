class Run < ActiveRecord::Base
  has_many :trips
  belongs_to :trip_import
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  after_save :apportion_run_based_trips

  attr_accessor :bulk_import, :do_not_version

  scope :has_odometer_log, where('odometer_start IS NOT NULL and odometer_end IS NOT NULL')
  scope :has_time_log, where('start_at IS NOT NULL and end_at IS NOT NULL')
  scope :data_entry_complete, where(:complete => true)
  scope :data_entry_not_complete, where(:complete => false)
  scope :for_date_range, lambda {|start_date, end_date| where("date >= ? AND date < ?", start_date, end_date) }
  scope :for_provider, lambda {|provider_id| where("runs.id IN (SELECT run_id FROM trips where allocation_id IN (SELECT id FROM allocations WHERE provider_id = ?))",provider_id)}

  point_in_time

  def created_by
    first_version.updated_by
  end
  
  def updated_by_user
    self.updated_by.nil? ? User.find(:first) : User.find(self.updated_by)
  end

  def display_name
    return name if name
    "unnamed run #{routematch_id} on #{date}"
  end
  
  def chronological_versions
    self.versions.sort{|t1,t2|t1.updated_at <=> t2.updated_at}.reverse
  end

  def ads_billable_hours
    BigDecimal.new(((((end_at - start_at) / 900).floor * 900) / 3600.0).to_s)
  end

  def ads_partner_cost
    if trips.first.allocation.name =~ /hourly/i
      BigDecimal.new("25.17") * ads_billable_hours 
    else
      BigDecimal.new("0")
    end
  end

  def ads_scheduling_fee
    if trips.first.allocation.name =~ /hourly/i
      BigDecimal.new("8.61") * ads_billable_hours
    else
      BigDecimal.new("0")
    end
  end

  def ads_total_cost
    ads_partner_cost + ads_scheduling_fee
  end
  private
  
  def create_new_version?
    !do_not_version?
  end
  
  def do_not_version?
    do_not_version == true || do_not_version.to_i == 1 || !complete || !complete_was
  end

  def apportion_run_based_trips
    unless bulk_import
      r = self.trips.current_versions.completed.includes(:allocation).where(:allocations => {:run_collection_method =>'runs'})
      trip_count = r.count 
      if trip_count > 0 
        ratio = 1 / trip_count.to_f

        unless end_at.nil? || start_at.nil?
          run_duration = (end_at - start_at) 
          trip_duration = (run_duration * ratio).floor
          run_duration_remaining = run_duration
        end

        unless odometer_start.nil? || odometer_end.nil?
          run_mileage = odometer_end - odometer_start 
          trip_mileage = ((run_mileage * ratio) * 100).floor.to_f / 100
          run_mileage_remaining = run_mileage
        end
        
        trip_position = 0

        for t in r
          trip_position += 1
          t.secondary_update = true

          unless trip_duration.nil?
            run_duration_remaining = (run_duration_remaining - trip_duration)
            t.apportioned_duration = (trip_duration + (trip_position == trip_count ? run_duration_remaining : 0))
          end

          unless trip_mileage.nil?
            run_mileage_remaining = (run_mileage_remaining - trip_mileage).round(2)
            t.apportioned_mileage = (trip_mileage + (trip_position == trip_count ? run_mileage_remaining : 0)).round(2)
          end

          t.save!
        end
      end
    end
  end

end
