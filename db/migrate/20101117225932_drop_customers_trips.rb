class DropCustomersTrips < ActiveRecord::Migration
  def self.up
    drop_table :customers_trips
  end

  def self.down
    create_table :customers_trips, :id => false do |t|
      t.references :customer, :trip
    end
 end
end
