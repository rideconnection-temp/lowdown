class DeversionSummaryRows < ActiveRecord::Migration
  def self.up
    drop_table :summary_rows
    create_table :summary_rows do |t|
      t.string :summary_id
      t.string :purpose
      t.integer :in_district_trips
      t.integer :updated_by
      t.integer :out_of_district_trips
    end
  end

  def self.down
    drop_table :summary_rows
    create_table :summary_rows, :id => false, :force => true do |t|
      t.string :id, :limit => 36, :null => false
      t.string :base_id, :limit => 36
      t.datetime :valid_start
      t.datetime :valid_end
      t.string :summary_id
      t.string :purpose
      t.integer :in_district_trips
      t.integer :updated_by
      t.integer :out_of_district_trips
    end
  end
end
