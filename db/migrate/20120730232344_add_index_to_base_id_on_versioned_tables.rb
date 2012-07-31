class AddIndexToBaseIdOnVersionedTables < ActiveRecord::Migration
  def self.up
    add_index :trips,     :base_id
    add_index :runs,      :base_id
    add_index :summaries, :base_id
  end

  def self.down
    remove_index :trips,     :base_id
    remove_index :runs,      :base_id
    remove_index :summaries, :base_id
  end
end
