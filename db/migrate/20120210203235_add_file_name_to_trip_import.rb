class AddFileNameToTripImport < ActiveRecord::Migration
  def self.up
    change_table :trip_imports do |t|
      t.string :file_name
    end
  end

  def self.down
    change_table :trip_imports do |t|
      t.remove :file_name
    end
  end
end
