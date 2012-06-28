class RenameSpdOfficeInTrips < ActiveRecord::Migration
  def self.up
    rename_column :trips, :spd_office, :case_manager_office
  end

  def self.down
    rename_column :trips, :case_manager_office, :spd_office
  end
end
