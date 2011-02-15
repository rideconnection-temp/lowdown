class AddCustomerIndexToTrips < ActiveRecord::Migration
  def self.up
    add_index :trips, :customer_id
  end

  def self.down
  end
end
