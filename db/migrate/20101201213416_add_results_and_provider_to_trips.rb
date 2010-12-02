class AddResultsAndProviderToTrips < ActiveRecord::Migration
  def self.up
    add_column :trips, :result_code, :string, :limit => 5
    add_column :trips, :provider_code, :string, :limit => 10 
		rename_column :trips, :trip_mobility, :mobility
    rename_column :trips, :trip_purpose_type, :purpose_type
#   Mobility kind will go in a lookup table for mobility
    remove_column :trips, :trip_mobility_kind
  end

  def self.down
    remove_column :trips, :result_code
    remove_column :trips, :provider_code
    rename_column :trips, :purpose_type, :trip_purpose_type
		rename_column :trips, :mobility, :trip_mobility
    add_column :trips, :trip_mobility_kind, :integer
  end
end
