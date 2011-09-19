class ChangeAllocationsAddInactivatedOn < ActiveRecord::Migration
  def self.up
    add_column :allocations, :inactivated_on, :date
  end

  def self.down
    remove_column :allocations, :inactivated_on
  end
end
