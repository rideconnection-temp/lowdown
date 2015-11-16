class AddIndexesToAddressesAndCustomers < ActiveRecord::Migration
  def change
    add_index :customers, :routematch_customer_id, unique: true
    add_index :addresses, :routematch_address_id, unique: true
  end
end
