class AddEstimatedIndividualFareToTrips < ActiveRecord::Migration
  def self.up
    add_column :trips, :estimated_individual_fare, :decimal, :precision => 10, :scale => 2
  end

  def self.down
    remove_column :trips, :estimated_individual_fare
  end
end
