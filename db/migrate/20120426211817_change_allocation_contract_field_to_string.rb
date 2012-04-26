class ChangeAllocationContractFieldToString < ActiveRecord::Migration
  def self.up
    change_column :allocations, :contract, :string
  end

  def self.down
    change_column :allocations, :contract, :decimal, :precision => 10, :scale => 2
  end
end
