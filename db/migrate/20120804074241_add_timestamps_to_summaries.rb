class AddTimestampsToSummaries < ActiveRecord::Migration
  def self.up
    add_column :summaries, :created_at, :datetime
    add_column :summaries, :updated_at, :datetime
  end

  def self.down
    remove_column :summaries, :created_at
    remove_column :summaries, :updated_at
  end
end
