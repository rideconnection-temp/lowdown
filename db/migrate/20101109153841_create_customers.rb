class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.integer :routematch_customer_id, :references=>nil
      t.string :last_name
      t.string :first_name
      t.string :middle_initial
      t.string :sex
      t.string :race
      t.string :mobility
      t.string :telephone_primary
      t.string :telephone_primary_extension
      t.string :telephone_secondary
      t.string :telephone_secondary_extension
      t.string :language_preference
      t.date :birthdate
      t.string :email
      t.string :customer_type
      t.integer :monthy_household_income
      t.integer :household_size
      t.integer :address_id

      t.timestamps
    end
  end

  def self.down
    drop_table :customers
  end
end
