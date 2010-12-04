class AddProviderIdToTrips < ActiveRecord::Migration
  def self.up
    add_column :trips, :provider_id, :integer
  end

  def self.down
  end
end
