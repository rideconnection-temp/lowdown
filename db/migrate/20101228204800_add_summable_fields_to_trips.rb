class AddSummableFieldsToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.integer :duration
      t.decimal :mileage, :precision => 6, :scale => 1
      t.integer :apportioned_duration
      t.decimal :apportioned_mileage, :precision => 6, :scale => 1
      t.decimal :apportioned_fare, :precision => 10, :scale => 2
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :duration
      t.remove :mileage
      t.remove :apportioned_duration
      t.remove :apportioned_mileage
      t.remove :apportioned_fare
    end
  end
end
