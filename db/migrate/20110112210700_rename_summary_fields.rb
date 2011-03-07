class RenameSummaryFields < ActiveRecord::Migration
  def self.up
    change_table :summary_rows do |t|
      t.integer :allocation_id
      t.remove :allocations_id
    end
  end

  def self.down
    change_table :summary_rows do |t|
      t.integer :allocations_id
      t.remove :allocation_id
    end
  end
end
