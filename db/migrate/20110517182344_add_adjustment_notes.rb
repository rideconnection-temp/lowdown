class AddAdjustmentNotes < ActiveRecord::Migration
  def self.up
    add_column :summaries, :adjustment_notes, :text
    add_column :trips, :adjustment_notes, :text
    add_column :runs, :adjustment_notes, :text
  end

  def self.down
  end
end
