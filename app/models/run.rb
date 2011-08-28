class Run < ActiveRecord::Base
  has_many :trips
  belongs_to :trip_import
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  after_save :apportion_run_based_trips

  attr_accessor :bulk_import, :do_not_version

  scope :has_odometer_log, where('odometer_start IS NOT NULL and odometer_end IS NOT NULL')
  scope :has_time_log, where('start_at IS NOT NULL and end_at IS NOT NULL')

  point_in_time

  def created_by
    return first_version.updated_by
  end
  
  def updated_by_user
    return (self.updated_by.nil? ? User.find(:first) : User.find(self.updated_by)) #right now, imports run through the command line will have no user info
  end

  def display_name
    return name if name
    return "unnamed run #{routematch_id} on #{date}"
  end
  
  def chronological_versions
    return self.versions.sort{|t1,t2|t1.updated_at <=> t2.updated_at}.reverse
  end

  private
  
  def create_new_version?
    !do_not_version?
  end
  
  def do_not_version?
    do_not_version.to_i == 1
  end

  def apportion_run_based_trips
    unless bulk_import
      r = self.trips.current_versions.completed.includes(:allocation).where(:allocations => {:run_collection_method =>'runs'})
      trip_count = r.count 
      if trip_count > 0 
        ratio = 1 / trip_count.to_f

        run_duration = ((end_at - start_at) / 60).to_i
        run_mileage = odometer_end - odometer_start
        
        trip_duration = ((run_duration * ratio) * 100).floor.to_f / 100
        trip_mileage = ((run_mileage * ratio) * 100).floor.to_f / 100
        
        run_duration_remaining = run_duration
        run_mileage_remaining = run_mileage

        trip_position = 0

        for t in r
          trip_position += 1
          t.secondary_update = true

          run_duration_remaining = (run_duration_remaining - trip_duration).round(2)
          t.apportioned_duration = (trip_duration + (trip_position == trip_count ? run_duration_remaining : 0)).round(2)

          run_mileage_remaining = (run_mileage_remaining - trip_mileage).round(2)
          t.apportioned_mileage = (trip_mileage + (trip_position == trip_count ? run_mileage_remaining : 0)).round(2)

          t.save!
        end
      end
    end
  end

end
