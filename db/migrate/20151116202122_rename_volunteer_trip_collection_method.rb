class RenameVolunteerTripCollectionMethod < ActiveRecord::Migration
  def change
    rename_column :allocations, :volunteer_trip_collection_method, :driver_type_collection_method
  end
end
