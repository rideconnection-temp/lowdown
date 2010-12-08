class AddAllocationIdToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.integer :allocation_id
      t.remove  :provider_id
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :allocation_id
      t.integer  :provider_id
    end
  end
end
