class AddElderlyAndDisabledOnlyToFlexReports < ActiveRecord::Migration
  def self.up
    add_column :flex_reports, :elderly_and_disabled_only, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :flex_reports, :elderly_and_disabled_only
  end
end
