class FixSummaryAlloc < ActiveRecord::Migration
  def self.up
    change_table :summaries do |t|
      t.decimal :funds, :precision => 10, :scale => 2
      t.references :allocation
    end
    change_table :summary_rows do |t|
      t.remove :allocation_id
    end
  end

  def self.down
    change_table :summaries do |t|
      t.remove :funds
      t.remove :allocation_id
    end

    change_table :summary_rows do |t|
      t.references :allocation
    end
  end
end
