class AddTripCollectionMethodsToFlexReports < ActiveRecord::Migration
  def change
    add_column :flex_reports, :trip_collection_method_list, :text
  end
end
