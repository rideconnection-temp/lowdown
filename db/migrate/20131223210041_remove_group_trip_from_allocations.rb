class RemoveGroupTripFromAllocations < ActiveRecord::Migration
  def self.up
    change_table :allocations do |t|
      t.remove :group_trip
    end
  end

  def self.down
    change_table :allocations do |t|
      t.boolean :group_trip
    end
  end
end
