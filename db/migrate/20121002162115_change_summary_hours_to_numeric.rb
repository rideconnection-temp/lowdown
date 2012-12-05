class ChangeSummaryHoursToNumeric < ActiveRecord::Migration
  def self.up
    change_column :summaries, :driver_hours_paid, :decimal, :precision => 7, :scale => 2
    change_column :summaries, :driver_hours_volunteer, :decimal, :precision => 7, :scale => 2
    change_column :summaries, :escort_hours_volunteer, :decimal, :precision => 7, :scale => 2
    change_column :summaries, :administrative_hours_volunteer, :decimal, :precision => 7, :scale => 2
  end

  def self.down
    change_column :summaries, :driver_hours_paid, :integer
    change_column :summaries, :driver_hours_volunteer, :integer
    change_column :summaries, :escort_hours_volunteer, :integer
    change_column :summaries, :administrative_hours_volunteer, :integer
  end
end
