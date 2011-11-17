class RebuildSummaryRowsTable < ActiveRecord::Migration
  def self.up
    create_table "summary_rows", :force => true do |t|
      t.integer "summary_id"
      t.string  "purpose"
      t.integer "in_district_trips"
      t.integer "out_of_district_trips"
      t.integer "updated_by"
    end
  end

  def self.down
    drop_table :summary_rows
  end
end
