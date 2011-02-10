class MakeMileageFieldsMoreCapacious < ActiveRecord::Migration
  def self.up
    change_column :trips, :mileage, :decimal, {:precision => 8, :scale => 1}
    change_column :trips, :apportioned_mileage, :decimal, {:precision => 9, :scale => 2}
  end

  def self.down
    change_column :trips, :mileage, :decimal, {:precision => 6, :scale => 1}
    change_column :trips, :apportioned_mileage, :decimal, {:precision => 7, :scale => 2}
  end
end
