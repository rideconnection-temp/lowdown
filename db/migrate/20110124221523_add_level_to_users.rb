class AddLevelToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.integer :level, :default=>0
    end
  end

  def self.down
    change_table :users do |t|
      t.remove :level
    end
  end
end
