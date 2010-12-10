class MakeCustomerPayNumeric < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.remove :customer_pay
    end
    change_table :trips do |t|
      t.decimal :customer_pay, :precision => 10, :scale => 2
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :customer_pay
    end
    change_table :trips do |t|
      t.boolean :customer_pay
    end

  end
end
