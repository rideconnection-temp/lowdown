class AddProviderTypeNameListToFlexReport < ActiveRecord::Migration
  def self.up
    add_column :flex_reports, :reporting_agency_type_name_list, :text
    add_column :flex_reports, :provider_type_name_list, :text
  end

  def self.down
    remove_column :flex_reports, :reporting_agency_type_name_list
    remove_column :flex_reports, :provider_type_name_list, :text
  end
end
