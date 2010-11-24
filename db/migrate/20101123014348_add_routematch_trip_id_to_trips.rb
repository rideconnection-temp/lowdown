class AddRoutematchTripIdToTrips < ActiveRecord::Migration
  def self.up
	change_table :trips do |t|
		t.integer :routematch_trip_id
	end
  end

  def self.down
	change_table :trips do |t|
		t.remove :routematch_trip_id
	end
  end
end
