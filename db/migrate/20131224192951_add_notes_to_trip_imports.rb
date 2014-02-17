class AddNotesToTripImports < ActiveRecord::Migration
  def self.up
    change_table :trip_imports do |t|
      t.text :notes
    end
  end

  def self.down
    change_table :trip_imports do |t|
      t.remove :notes
    end
  end
end
