class AddVeteranStatusToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :veteran_status, :string
  end

  def self.down
    remove_column :customers, :veteran_status
  end
end
