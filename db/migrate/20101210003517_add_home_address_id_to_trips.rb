class AddHomeAddressIdToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.integer :home_address_id
      t.change :override, :string
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :home_address_id
      t.change :override, :boolean
    end
  end
end
