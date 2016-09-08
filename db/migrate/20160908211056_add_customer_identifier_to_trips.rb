class AddCustomerIdentifierToTrips < ActiveRecord::Migration
  def change
    change_table :trips do |t|
      t.string :customer_identifier
    end
  end
end
