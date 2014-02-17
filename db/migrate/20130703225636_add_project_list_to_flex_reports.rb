class AddProjectListToFlexReports < ActiveRecord::Migration
  def self.up
    add_column :flex_reports, :project_list, :text
  end

  def self.down
    remove_column :flex_reports, :project_list
  end
end
