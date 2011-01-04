class Run < ActiveRecord::Base
  has_many :trips

  after_save :apportion_run_based_trips

  attr_accessor :bulk_import

  def display_name
    return name if name
    return "unnamed run #{id} on #{date}"
  end

  private

  def apportion_run_based_trips
    unless bulk_import
      if self.trips.first.allocation.run_collection_method == 'runs'
        r = self.trips.completed
        trip_count = r.count 
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

          run_duration_remaining -= trip_duration 
          run_duration_remaining = run_duration_remaining.round(2)
          t.apportioned_duration = trip_duration + (trip_position == trip_count ? run_duration_remaining : 0)

          run_mileage_remaining -= trip_mileage
          run_mileage_remaining = run_mileage_remaining.round(2)
          t.apportioned_mileage = trip_mileage + (trip_position == trip_count ? run_mileage_remaining : 0)

          t.save!
        end
      end
    end
  end

end
