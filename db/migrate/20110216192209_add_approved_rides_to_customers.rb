class AddApprovedRidesToCustomers < ActiveRecord::Migration
  def self.up
    change_table :customers do |t|
      t.integer :approved_rides
    end
  end

  def self.down
    change_table :customers do |t|
      t.remove :approved_rides
    end
  end
end
