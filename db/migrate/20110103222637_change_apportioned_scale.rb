class ChangeApportionedScale < ActiveRecord::Migration
  def self.up
    change_column :trips, :apportioned_mileage, :decimal, :precision => 7, :scale => 2
    change_column :trips, :apportioned_duration, :decimal, :precision => 7, :scale => 2
  end

  def self.down
    change_column :trips, :apportioned_mileage, :decimal, :precision => 6, :scale => 1
    change_column :trips, :apportioned_duration, :integer
  end
end
