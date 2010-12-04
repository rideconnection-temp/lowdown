class AddNameToRuns < ActiveRecord::Migration
  def self.up
    change_table :runs do |t|
      t.string :name
      t.integer :routematch_id
      t.remove :routematch_share_id
    end
  end

  def self.down
    change_table :runs do |t|
      t.remove :name
      t.remove :routematch_id
      t.integer :routematch_share_id
    end
  end
end
