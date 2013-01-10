class AddEligibilityToAllocations < ActiveRecord::Migration
  def self.up
    add_column :allocations, :eligibility, :string
  end

  def self.down
    remove_column :allocations, :eligibility
  end
end
