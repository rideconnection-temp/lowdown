class RemoveDateFromTripImport < ActiveRecord::Migration
  def self.up
    remove_column :trip_imports, :date
  end

  def self.down
    add_column :trip_imports, :date, :datetime
  end
end
