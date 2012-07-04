class RemoveContractFromAllocations < ActiveRecord::Migration
  def self.up
    remove_column :allocations, :contract
  end

  def self.down
    add_column :allocations, :contract, :string
  end
end
