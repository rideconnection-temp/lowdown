class RemoveAdjustmentFields < ActiveRecord::Migration
  def self.up
    remove_column :flex_reports, :adjustment, :adjustment_start_date, :adjustment_end_date
  end

  def self.down
    change_table :flex_reports do |t|
      t.boolean "adjustment"
      t.date    "adjustment_start_date"
      t.date    "adjustment_end_date"
    end
  end
end
