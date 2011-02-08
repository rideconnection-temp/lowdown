class AddTimestampsToRuns < ActiveRecord::Migration
  def self.up
    change_table :runs do |t|
      t.timestamps
    end
  end

  def self.down
    change_table :runs do |t|
      t.remove :created_at
      t.remove :updated_at
    end
  end
end
