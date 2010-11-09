# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101109153910) do

  create_table "addresses", :force => true do |t|
    t.integer  "routematch_address_id"
    t.string   "common_name"
    t.string   "building_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "postal_code"
    t.string   "x_coordinate"
    t.string   "y_coordinate"
    t.boolean  "in_trimet_district"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "customers", :force => true do |t|
    t.integer  "routematch_customer_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "middle_initial"
    t.string   "sex"
    t.string   "race"
    t.string   "mobility"
    t.string   "telephone_primary"
    t.string   "telephone_primary_extension"
    t.string   "telephone_secondary"
    t.string   "telephone_secondary_extension"
    t.string   "language_preference"
    t.date     "birthdate"
    t.string   "email"
    t.string   "customer_type"
    t.integer  "monthy_household_income"
    t.integer  "household_size"
    t.integer  "address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "customers_trips", :id => false, :force => true do |t|
    t.integer "customer_id"
    t.integer "trip_id"
  end

  create_table "trips", :force => true do |t|
    t.date     "date"
    t.boolean  "cancelled"
    t.boolean  "noshow"
    t.boolean  "completed"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "odometer_start"
    t.integer  "odometer_end"
    t.float    "fare"
    t.boolean  "customer_pay"
    t.string   "trip_purpose_type"
    t.integer  "guest_count"
    t.integer  "attendant_count"
    t.string   "trip_mobility"
    t.string   "trip_mobility_kind"
    t.float    "calculated_bpa_fare"
    t.string   "bpa_driver_name"
    t.boolean  "volunteer_trip"
    t.boolean  "in_trimet_district"
    t.float    "bpa_billing_distance"
    t.integer  "routematch_share_id"
    t.boolean  "override"
    t.float    "estimated_trip_distance_in_miles"
    t.integer  "pickup_address_id"
    t.integer  "routematch_pickup_address_id"
    t.integer  "dropoff_address_id"
    t.integer  "routematch_dropoff_address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
