class AddCustomeridToTrips < ActiveRecord::Migration
  def self.up
	change_table :trips do |t|
		t.references :customer
	end
  end

  def self.down
	change_table :trips do |t|
		t.remove :customer_id
	end
  end
end
