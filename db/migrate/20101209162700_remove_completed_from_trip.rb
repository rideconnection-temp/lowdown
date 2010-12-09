class RemoveCompletedFromTrip < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.remove :completed
      t.remove :noshow
      t.remove :cancelled
    end
  end

  def self.down
    change_table :trips do |t|
      t.boolean :completed
      t.boolean :noshow
      t.boolean :cancelled
    end
  end
end
