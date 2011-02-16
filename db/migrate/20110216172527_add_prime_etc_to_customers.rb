class AddPrimeEtcToCustomers < ActiveRecord::Migration
  def self.up
    change_table :customers do |t|
      t.string :case_manager
      t.date :date_enrolled
      t.string :prime_number
      t.date :service_end
    end
  end

  def self.down
    change_table :customers do |t|
      t.remove :case_manager
      t.remove :remove_enrolled
      t.remove :prime_number
      t.remove :service_end
    end
  end
end
