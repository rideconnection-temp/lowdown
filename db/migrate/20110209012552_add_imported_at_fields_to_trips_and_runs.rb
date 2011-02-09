class AddImportedAtFieldsToTripsAndRuns < ActiveRecord::Migration
  def self.up
    change_table(:trips) { |t| t.datetime :imported_at }
    change_table(:runs)  { |t| t.datetime :imported_at }
  end

  def self.down
    change_table(:trips) { |t| t.remove :imported_at }
    change_table(:runs)  { |t| t.remove :imported_at }
  end
end
