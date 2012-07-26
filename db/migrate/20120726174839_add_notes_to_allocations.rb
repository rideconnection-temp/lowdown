class AddNotesToAllocations < ActiveRecord::Migration
  def self.up
    add_column :allocations, :notes, :text
  end

  def self.down
    remove_column :allocations, :notes
  end
end
