class AddAdminOpsVehicleMaintSettingsToAllocations < ActiveRecord::Migration
  def self.up
    change_table :allocations do |t|
      t.string :admin_ops_data, :limit => 15
      t.string :vehicle_maint_data, :limit => 15
    end
  end

  def self.down
    change_table :allocations do |t|
      t.remove :admin_ops_data
      t.remove :vehicle_maint_data
    end
  end
end
