class CreateRuns < ActiveRecord::Migration
  def self.up
    create_table :runs do |t|
      t.date :date
      t.integer :routematch_share_id

      t.timestamps
    end
  end

  def self.down
    drop_table :runs
  end
end
