class MakeMoneyBigdecimal < ActiveRecord::Migration
  def self.up
    change_column :trips, :fare, :decimal, :precision => 10, :scale => 2
    change_column :trips, :calculated_bpa_fare, :decimal, :precision => 10, :scale => 2
  end

  def self.down
    change_column :trips, :fare, :float
    change_column :trips, :calculated_bpa_fare, :float
  end
end
