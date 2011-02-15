class AddAdminOpsEtcToSummary < ActiveRecord::Migration
  def self.up
    change_table :summaries do |t|
      t.integer :administrative
      t.integer :operations
      t.integer :vehicle_maint
    end
  end

  def self.down
    change_table :summaries do |t|
      t.remove :administrative
      t.remove :operations
      t.remove :vehicle_maint
    end
  end
end
