class AddSubtitleToFlexReports < ActiveRecord::Migration
  def self.up
    add_column :flex_reports, :subtitle, :text
  end

  def self.down
    remove_column :flex_reports, :subtitle
  end
end
