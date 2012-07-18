class AddReportingAgencyListToFlexReports < ActiveRecord::Migration
  def self.up
    add_column :flex_reports, :reporting_agency_list, :text
    remove_column :flex_reports, :subcontractor_name_list
  end

  def self.down
    add_column :flex_reports, :subcontractor_name_list, :text
    remove_column :flex_reports, :reporting_agency_list
  end
end
