# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20121228004228) do

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

  create_table "allocations", :force => true do |t|
    t.string  "name"
    t.boolean "group_trip"
    t.integer "project_id"
    t.integer "provider_id"
    t.string  "county"
    t.string  "trip_collection_method"
    t.string  "run_collection_method"
    t.string  "cost_collection_method"
    t.string  "routematch_override"
    t.string  "routematch_provider_code"
    t.date    "inactivated_on"
    t.string  "program"
    t.string  "admin_ops_data",              :limit => 15
    t.string  "vehicle_maint_data",          :limit => 15
    t.integer "trimet_program_id"
    t.integer "trimet_provider_id"
    t.integer "trimet_report_group_id"
    t.integer "override_id"
    t.date    "activated_on"
    t.integer "reporting_agency_id"
    t.text    "notes"
    t.boolean "do_not_show_on_flex_reports",               :default => false, :null => false
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
    t.integer  "monthly_household_income"
    t.integer  "household_size"
    t.integer  "address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prime_number"
    t.boolean  "disabled"
    t.string   "veteran_status"
  end

  create_table "flex_reports", :force => true do |t|
    t.string  "name"
    t.date    "start_date"
    t.date    "end_date"
    t.string  "group_by"
    t.text    "allocation_list"
    t.text    "field_list"
    t.boolean "pending"
    t.text    "description"
    t.integer "position"
    t.text    "funding_subsource_name_list"
    t.text    "provider_list"
    t.text    "program_name_list"
    t.text    "county_name_list"
    t.text    "reporting_agency_list"
    t.text    "subtitle"
    t.integer "report_category_id"
  end

  create_table "mobilities", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "overrides", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "funding_source"
    t.string   "funding_subsource"
    t.string   "project_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "providers", :force => true do |t|
    t.string   "name",          :limit => 50
    t.string   "provider_type", :limit => 15
    t.string   "agency",        :limit => 50
    t.string   "branch",        :limit => 50
    t.string   "routematch_id", :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_name",    :limit => 10
  end

  create_table "races", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "report_categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "runs", :force => true do |t|
    t.integer  "base_id",                             :null => false
    t.datetime "valid_start",                         :null => false
    t.datetime "valid_end",                           :null => false
    t.date     "date"
    t.string   "name"
    t.integer  "routematch_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "odometer_start"
    t.integer  "odometer_end"
    t.integer  "escort_count"
    t.integer  "trip_import_id"
    t.integer  "updated_by"
    t.boolean  "complete",         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "imported_at"
    t.text     "adjustment_notes"
  end

  add_index "runs", ["base_id"], :name => "index_runs_on_base_id"

  create_table "summaries", :force => true do |t|
    t.integer  "base_id",                                                                          :null => false
    t.datetime "valid_start",                                                                      :null => false
    t.datetime "valid_end",                                                                        :null => false
    t.date     "period_start"
    t.date     "period_end"
    t.integer  "total_miles"
    t.decimal  "driver_hours_paid",              :precision => 7,  :scale => 2
    t.decimal  "driver_hours_volunteer",         :precision => 7,  :scale => 2
    t.decimal  "escort_hours_volunteer",         :precision => 7,  :scale => 2
    t.decimal  "administrative_hours_volunteer", :precision => 7,  :scale => 2
    t.integer  "unduplicated_riders"
    t.integer  "turn_downs"
    t.decimal  "agency_other",                   :precision => 10, :scale => 2
    t.decimal  "donations",                      :precision => 10, :scale => 2
    t.decimal  "funds",                          :precision => 10, :scale => 2
    t.integer  "allocation_id"
    t.integer  "updated_by"
    t.boolean  "complete",                                                      :default => false
    t.decimal  "administrative",                 :precision => 10, :scale => 2
    t.decimal  "operations",                     :precision => 10, :scale => 2
    t.decimal  "vehicle_maint",                  :precision => 10, :scale => 2
    t.text     "adjustment_notes"
    t.datetime "first_version_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "summaries", ["base_id"], :name => "index_summaries_on_base_id"

  create_table "summary_rows", :force => true do |t|
    t.integer "summary_id"
    t.string  "purpose"
    t.integer "in_district_trips"
    t.integer "out_of_district_trips"
    t.integer "updated_by"
  end

  create_table "trimet_programs", :force => true do |t|
    t.integer  "trimet_identifier"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "trimet_providers", :force => true do |t|
    t.integer  "trimet_identifier"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "trimet_report_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "trip_imports", :force => true do |t|
    t.string   "file_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_name"
  end

  create_table "trips", :force => true do |t|
    t.integer  "base_id",                                                                                           :null => false
    t.datetime "valid_start",                                                                                       :null => false
    t.datetime "valid_end",                                                                                         :null => false
    t.date     "date"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "odometer_start"
    t.integer  "odometer_end"
    t.decimal  "fare",                                            :precision => 10, :scale => 2
    t.string   "purpose_type"
    t.integer  "guest_count"
    t.integer  "attendant_count"
    t.string   "mobility"
    t.decimal  "calculated_bpa_fare",                             :precision => 10, :scale => 2
    t.string   "bpa_driver_name"
    t.boolean  "volunteer_trip"
    t.boolean  "in_trimet_district"
    t.float    "bpa_billing_distance"
    t.integer  "routematch_share_id"
    t.string   "override"
    t.float    "estimated_trip_distance_in_miles"
    t.integer  "pickup_address_id"
    t.integer  "routematch_pickup_address_id"
    t.integer  "dropoff_address_id"
    t.integer  "routematch_dropoff_address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.integer  "run_id"
    t.integer  "trip_import_id"
    t.integer  "routematch_trip_id"
    t.string   "result_code",                      :limit => 5
    t.string   "provider_code",                    :limit => 10
    t.integer  "allocation_id"
    t.integer  "home_address_id"
    t.decimal  "customer_pay",                                    :precision => 10, :scale => 2
    t.integer  "duration"
    t.decimal  "mileage",                                         :precision => 8,  :scale => 1
    t.decimal  "apportioned_duration",                            :precision => 7,  :scale => 2
    t.decimal  "apportioned_mileage",                             :precision => 9,  :scale => 2
    t.decimal  "apportioned_fare",                                :precision => 10, :scale => 2
    t.integer  "updated_by"
    t.datetime "imported_at"
    t.text     "adjustment_notes"
    t.string   "case_manager"
    t.date     "date_enrolled"
    t.date     "service_end"
    t.integer  "approved_rides"
    t.string   "case_manager_office",              :limit => 100
    t.boolean  "complete",                                                                       :default => false
    t.string   "original_override"
    t.string   "customer_type"
    t.decimal  "estimated_individual_fare",                       :precision => 10, :scale => 2
  end

  add_index "trips", ["base_id"], :name => "index_trips_on_base_id"
  add_index "trips", ["customer_id"], :name => "index_trips_on_customer_id"

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",   :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",   :null => false
    t.string   "password_salt",                       :default => "",   :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level"
    t.boolean  "active",                              :default => true, :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  add_foreign_key "customers", ["address_id"], "addresses", ["id"], :name => "customers_address_id_fkey"

end
