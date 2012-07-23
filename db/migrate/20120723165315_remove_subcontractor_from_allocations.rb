class RemoveSubcontractorFromAllocations < ActiveRecord::Migration
  def self.up
    remove_column :providers, :subcontractor
  end

  def self.down
    add_column :providers, :subcontractor, :string
  end
end
