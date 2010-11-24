class CreateTripImports < ActiveRecord::Migration
  def self.up
    create_table :trip_imports do |t|
      t.date :date
      t.string :file_path 

      t.timestamps
    end
  end

  def self.down
    drop_table :trip_imports
  end
end
