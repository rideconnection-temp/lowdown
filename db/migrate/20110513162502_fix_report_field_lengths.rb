class FixReportFieldLengths < ActiveRecord::Migration
  def self.up
    change_column :reports, :field_list, :text
    change_column :reports, :allocation_list, :text
  end

  def self.down
  end
end
