class AddOriginalOverrideToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.string :original_override
    end
  end

  def self.down
    change_table :trips do |t|
      t.remove :original_override
    end
  end
end
