class CreateTrips < ActiveRecord::Migration
  def self.up
    create_table :trips, :id =>false do |t|
      t.string :id, :limit => 36, :null => false, :primary_key
      t.string :base_id, :limit => 36
      t.datetime :valid_start
      t.datetime :valid_end
      t.date :date
      t.boolean :cancelled
      t.boolean :noshow
      t.boolean :completed
      t.datetime :start_at
      t.datetime :end_at
      t.integer :odometer_start
      t.integer :odometer_end
      t.float :fare
      t.boolean :customer_pay
      t.string :trip_purpose_type
      t.integer :guest_count
      t.integer :attendant_count
      t.string :trip_mobility
      t.string :trip_mobility_kind
      t.float :calculated_bpa_fare
      t.string :bpa_driver_name
      t.boolean :volunteer_trip
      t.boolean :in_trimet_district
      t.float :bpa_billing_distance
      t.integer :routematch_share_id
      t.boolean :override
      t.float :estimated_trip_distance_in_miles
      t.integer :pickup_address_id
      t.integer :routematch_pickup_address_id
      t.integer :dropoff_address_id
      t.integer :routematch_dropoff_address_id

      t.timestamps
    end
  end

  def self.down
    drop_table :trips
  end
end
