class AddTurnDowns < ActiveRecord::Migration
  def self.up
    change_table :summaries do |t|
      t.integer :turn_downs
      t.decimal :agency_other, :precision => 10, :scale => 2
      t.decimal :donations, :precision => 10, :scale => 2
    end
  end

  def self.down
    change_table :summaries do |t|
      t.remove :turn_downs
      t.remove :agency_other
      t.remove :donations
    end
  end
end
