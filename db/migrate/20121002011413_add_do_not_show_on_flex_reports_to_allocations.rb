class AddDoNotShowOnFlexReportsToAllocations < ActiveRecord::Migration
  def self.up
    add_column :allocations, :do_not_show_on_flex_reports, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :allocations, :do_not_show_on_flex_reports
  end
end
