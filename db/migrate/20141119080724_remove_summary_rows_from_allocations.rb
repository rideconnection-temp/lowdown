class RemoveSummaryRowsFromAllocations < ActiveRecord::Migration
  def up
    Allocation.where(trip_collection_method: 'summary_rows').update_all("trip_collection_method = 'summary'")
  end

  def down
    Allocation.where(trip_collection_method: 'summary').update_all("trip_collection_method = 'summary_rows'")
  end
end
