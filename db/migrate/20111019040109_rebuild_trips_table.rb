class RebuildTripsTable < ActiveRecord::Migration
  def self.up
    create_table "trips", :force => true do |t|
      t.integer  "base_id", :references => nil, :null => false
      t.datetime "valid_start", :null => false
      t.datetime "valid_end", :null => false
      t.date     "date"
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "odometer_start"
      t.integer  "odometer_end"
      t.decimal  "fare",                                           :precision => 10, :scale => 2
      t.string   "purpose_type"
      t.integer  "guest_count"
      t.integer  "attendant_count"
      t.string   "mobility"
      t.decimal  "calculated_bpa_fare",                            :precision => 10, :scale => 2
      t.string   "bpa_driver_name"
      t.boolean  "volunteer_trip"
      t.boolean  "in_trimet_district"
      t.float    "bpa_billing_distance"
      t.integer  "routematch_share_id", :references => nil
      t.string   "override"
      t.float    "estimated_trip_distance_in_miles"
      t.integer  "pickup_address_id", :references => :addresses
      t.integer  "routematch_pickup_address_id", :references => nil
      t.integer  "dropoff_address_id", :references => :addresses
      t.integer  "routematch_dropoff_address_id", :references => nil
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "customer_id"
      t.integer  "run_id", :references => nil
      t.integer  "trip_import_id"
      t.integer  "routematch_trip_id", :references => nil
      t.string   "result_code",                      :limit => 5
      t.string   "provider_code",                    :limit => 10
      t.integer  "allocation_id"
      t.integer  "home_address_id", :references => :addresses
      t.decimal  "customer_pay",                                   :precision => 10, :scale => 2
      t.integer  "duration"
      t.decimal  "mileage",                                        :precision => 8,  :scale => 1
      t.decimal  "apportioned_duration",                           :precision => 7,  :scale => 2
      t.decimal  "apportioned_mileage",                            :precision => 9,  :scale => 2
      t.decimal  "apportioned_fare",                               :precision => 10, :scale => 2
      t.integer  "updated_by"
      t.datetime "imported_at"
      t.text     "adjustment_notes"
      t.string   "case_manager"
      t.date     "date_enrolled"
      t.date     "service_end"
      t.integer  "approved_rides"
      t.string   "spd_office",                       :limit => 25
    end

    add_index "trips", ["customer_id"], :name => "index_trips_on_customer_id"
  end

  def self.down
    drop_table :trips
  end
end
