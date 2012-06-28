class RenameReportsModel < ActiveRecord::Migration
  def self.up
    rename_table :reports, :flex_reports
  end

  def self.down
    rename_table :flex_reports, :reports
  end
end
