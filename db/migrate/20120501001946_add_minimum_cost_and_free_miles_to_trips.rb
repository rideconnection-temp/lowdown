class AddMinimumCostAndFreeMilesToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.decimal "minimum_cost", :precision => 10, :scale => 2
      t.integer "free_miles"
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove "minimum_cost"
      t.remove "free_miles"
    end
  end
end
