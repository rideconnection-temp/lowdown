class AddRunIdToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.references :run
	end
  end

  def self.down
    change_table :trips do |t|
      t.remove :run_id
	end
  end
end
