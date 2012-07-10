class UpdateTripsCaseManagerLimit < ActiveRecord::Migration
  def self.up
    change_column :trips, :case_manager_office, :string, :limit => 100
  end

  def self.down
    change_column :trips, :case_manager_office, :string, :limit => 25
  end
end
