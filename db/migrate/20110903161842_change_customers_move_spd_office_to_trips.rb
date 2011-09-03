class ChangeCustomersMoveSpdOfficeToTrips < ActiveRecord::Migration
  def self.up
    add_column :trips, :spd_office, :string, :limit => 25 
    
    say_with_time "Updating Trips..." do
      Customer.find_each do |customer|
        customer.trips.current_versions.each do |trip|
          trip.spd_office = customer.spd_office
          trip.save
        end
      end
    end
    
    remove_column :customers, :spd_office
  end

  def self.down
    add_column :customers, :spd_office, :string, :limit => 25
    
    say_with_time "Updating Customers..." do
      # find_in_batches doesn't work for models with strings for ids :(
      Trip.all.each do |trip|
        trip.customer.update_attribute :spd_office, trip.spd_office
      end
    end
    
    remove_column :trips, :spd_office
  end
end
