class RemoveRoutematchOverrideFromAllocations < ActiveRecord::Migration
  def self.up
    remove_column :allocations, :routematch_override
  end

  def self.down
    add_column :allocations, :routematch_override, :string
  end
end
