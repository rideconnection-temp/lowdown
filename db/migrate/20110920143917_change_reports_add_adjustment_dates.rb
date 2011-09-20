class ChangeReportsAddAdjustmentDates < ActiveRecord::Migration
  def self.up
    add_column :reports, :adjustment_start_date, :date
    add_column :reports, :adjustment_end_date, :date
  end

  def self.down
    remove_column :reports, :adjustment_start_date
    remove_column :reports, :adjustment_end_date
  end
end
