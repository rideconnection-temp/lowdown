class CreateCustomersTrips < ActiveRecord::Migration
  def self.up
    create_table :customers_trips, :id => false do |t|
      t.references :customer, :trip
    end
  end

  def self.down
    drop_table :customers_trips
  end
end
