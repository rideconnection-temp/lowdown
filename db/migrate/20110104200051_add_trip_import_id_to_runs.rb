class AddTripImportIdToRuns < ActiveRecord::Migration
  def self.up
    change_table :runs do |t|
      t.integer :trip_import_id
    end
  end

  def self.down
    change_table :runs do |t|
      t.remove :trip_import_id
    end
  end
end
