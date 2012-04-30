class AddCustomerTypeToTrip < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.string :customer_type
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :customer_type
    end
  end
end
