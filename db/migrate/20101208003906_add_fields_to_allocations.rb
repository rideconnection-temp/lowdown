class AddFieldsToAllocations < ActiveRecord::Migration
  def self.up
    change_table :allocations do |t|
      t.boolean :group_trip
      t.integer :project_id
      t.integer :provider_id
      t.string :county
      t.string :trip_collection_method
      t.string :run_collection_method
      t.string :cost_collection_method
      t.string :routematch_override
      t.string :routematch_provider_code
    end
  end

  def self.down
    change_table :allocations do |t|
      t.remove :group_trip
      t.remove :project
      t.remove :provider
      t.remove :county
      t.remove :trip_collection_method
      t.remove :run_collection_method
      t.remove :cost_collection_method
      t.remove :routematch_override
      t.remove :routematch_provider_code
    end
  end
end
