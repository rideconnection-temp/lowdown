class AddContractAmountToAllocation < ActiveRecord::Migration
  def self.up
    change_table :allocations do |t|
      t.decimal :contract, :precision=>10, :scale=>2
    end
  end

  def self.down
    change_table :allocations do |t|
      t.remove :contract
    end
  end
end
