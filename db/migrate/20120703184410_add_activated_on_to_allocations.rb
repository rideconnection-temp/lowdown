class AddActivatedOnToAllocations < ActiveRecord::Migration
  def self.up
    add_column :allocations, :activated_on, :date
    Allocation.update_all :activated_on => "2011-07-01".to_date
  end

  def self.down
    remove_column :allocations, :activated_on
  end
end
