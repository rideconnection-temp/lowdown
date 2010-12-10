class AddEscortCountToRuns < ActiveRecord::Migration
  def self.up
    change_table :runs do |t|
      t.integer :escort_count, :default=>0
    end
  end

  def self.down
    change_table :runs do |t|
      t.remove :escort_count
    end
  end
end
