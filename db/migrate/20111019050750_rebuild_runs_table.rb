class RebuildRunsTable < ActiveRecord::Migration
  def self.up
    create_table "runs", :force => true do |t|
      t.integer  "base_id", :references => nil, :null => false
      t.datetime "valid_start", :null => false
      t.datetime "valid_end", :null => false
      t.date     "date"
      t.string   "name"
      t.integer  "routematch_id", :references => nil
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "odometer_start"
      t.integer  "odometer_end"
      t.integer  "escort_count"
      t.integer  "trip_import_id", :references => nil
      t.integer  "updated_by"
      t.boolean  "complete",                       :default => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "imported_at"
      t.text     "adjustment_notes"
    end
  end

  def self.down
    drop_table :runs
  end
end
