class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.integer :routematch_address_id
      t.string :common_name
      t.string :building_name
      t.string :address_1
      t.string :address_2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :x_coordinate
      t.string :y_coordinate
      t.boolean :in_trimet_district

      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
