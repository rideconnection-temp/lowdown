class RebuildSummariesTable < ActiveRecord::Migration
  def self.up
    create_table "summaries", :force => true do |t|
      t.integer  "base_id", :references => nil, :null => false
      t.datetime "valid_start", :null => false
      t.datetime "valid_end", :null => false
      t.date     "period_start"
      t.date     "period_end"
      t.integer  "total_miles"
      t.integer  "driver_hours_paid"
      t.integer  "driver_hours_volunteer"
      t.integer  "escort_hours_volunteer"
      t.integer  "administrative_hours_volunteer"
      t.integer  "unduplicated_riders"
      t.integer  "turn_downs"
      t.decimal  "agency_other",                                 :precision => 10, :scale => 2
      t.decimal  "donations",                                    :precision => 10, :scale => 2
      t.decimal  "funds",                                        :precision => 10, :scale => 2
      t.integer  "allocation_id"
      t.integer  "updated_by"
      t.boolean  "complete",                                                                    :default => false
      t.integer  "administrative"
      t.integer  "operations"
      t.integer  "vehicle_maint"
      t.text     "adjustment_notes"
    end
  end

  def self.down
    drop_table :summaries
  end
end
