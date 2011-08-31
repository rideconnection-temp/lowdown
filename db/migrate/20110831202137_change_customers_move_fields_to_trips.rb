class ChangeCustomersMoveFieldsToTrips < ActiveRecord::Migration
  def self.up
    add_column :trips, :case_manager, :string 
    add_column :trips, :date_enrolled, :date
    add_column :trips, :service_end,  :date
    add_column :trips, :approved_rides, :integer
    
    say_with_time "Updating Trips..." do
      Customer.find_each do |customer|
        customer.trips.current_versions.each do |trip|
          trip.case_manager   = customer.case_manager
          trip.date_enrolled  = customer.date_enrolled
          trip.service_end    = customer.service_end
          trip.approved_rides = customer.approved_rides
          trip.save
        end
      end
    end
    
    remove_column :customers, :case_manager
    remove_column :customers, :date_enrolled
    remove_column :customers, :service_end
    remove_column :customers, :approved_rides
  end

  def self.down
    add_column :customers, :case_manager, :string 
    add_column :customers, :date_enrolled, :date
    add_column :customers, :service_end,  :date
    add_column :customers, :approved_rides, :integer
    
    say_with_time "Updating Customers..." do
      # find_in_batches doesn't work for models with strings for ids :(
      Trip.all.each do |trip|
        customer = trip.customer
        customer.case_manager   = trip.case_manager
        customer.date_enrolled  = trip.date_enrolled
        customer.service_end    = trip.service_end
        customer.approved_rides = trip.approved_rides
        customer.save
      end
    end
    
    remove_column :trips, :case_manager
    remove_column :trips, :date_enrolled
    remove_column :trips, :service_end
    remove_column :trips, :approved_rides
  end
end
