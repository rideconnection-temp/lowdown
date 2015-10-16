class AddVolunteerTrackingToAllocations < ActiveRecord::Migration
  def change
    add_column :allocations, :volunteer_trip_collection_method, :string, limit: 255

    reversible do |dir|
      dir.up do
        Allocation.update_all volunteer_trip_collection_method: 'mixed'
      end
    end
  end
end
