class AddTrimetReportGroupIdToAllocations < ActiveRecord::Migration
  def self.up
    add_column :allocations, :trimet_report_group_id, :integer
  end

  def self.down
    remove_column :allocations, :trimet_report_group_id
  end
end
