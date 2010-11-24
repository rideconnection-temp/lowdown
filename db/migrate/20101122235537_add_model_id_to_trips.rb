class AddModelIdToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.references :trip_import
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :trip_import_id
    end
  end
end
