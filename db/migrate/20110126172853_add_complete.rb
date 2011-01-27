class AddComplete < ActiveRecord::Migration
  def self.up
    change_table :summaries do |t|
      t.boolean :complete, :default=>false
    end
    change_table :runs do |t|
      t.boolean :complete, :default=>false
    end
  end

  def self.down
    change_table :summaries do |t|
      t.remove :complete
    end
    change_table :runs do |t|
      t.remove :complete
    end
  end
end
