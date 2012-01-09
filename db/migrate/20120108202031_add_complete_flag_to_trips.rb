class AddCompleteFlagToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.boolean :complete, :default => false
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :complete
    end
  end
end
