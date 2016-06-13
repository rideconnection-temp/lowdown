class AddPrimeNumberToTrips < ActiveRecord::Migration
  def change
    add_column :trips, :funding_source_customer_id, :string, limit: 50
  end
end
