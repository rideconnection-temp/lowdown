class AddSpdOfficeToCustomers < ActiveRecord::Migration
  def self.up
    change_table :customers do |t|
      t.string :spd_office, :limit => 25
    end
  end

  def self.down
    change_table :customers do |t|
      t.remove :spd_office 
    end
  end
end
