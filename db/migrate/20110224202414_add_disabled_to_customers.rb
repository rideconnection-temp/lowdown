class AddDisabledToCustomers < ActiveRecord::Migration
  def self.up
    change_table :customers do |t|
      t.boolean :disabled
    end
  end

  def self.down
    change_table :customers do |t|
      t.remove :disabled
    end
  end
end
