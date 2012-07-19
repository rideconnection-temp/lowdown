class ChangeSummaryFieldsToNumeric < ActiveRecord::Migration
  def self.up
    change_column :summaries, :administrative, :decimal, :precision => 10, :scale => 2
    change_column :summaries, :operations, :decimal, :precision => 10, :scale => 2
    change_column :summaries, :vehicle_maint, :decimal, :precision => 10, :scale => 2
  end

  def self.down
    change_column :summaries, :administrative, :integer
    change_column :summaries, :operations, :integer
    change_column :summaries, :vehicle_maint, :integer
  end
end
