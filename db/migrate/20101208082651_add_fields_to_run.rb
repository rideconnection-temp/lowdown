class AddFieldsToRun < ActiveRecord::Migration
  def self.up
    change_table :runs do |t|
      t.datetime :start_at
      t.datetime :end_at
      t.integer :odometer_start
      t.integer :odometer_end
    end
  end

  def self.down
    change_table :runs do |t|
      t.remove :start_at
      t.remove :end_at
      t.remove :odometer_start
      t.remove :odometer_end
    end
  end
end
