class AddReportingAgencyToAllocations < ActiveRecord::Migration
  def self.up
    add_column :allocations, :reporting_agency_id, :integer, :references => :providers
    Allocation.update_all "reporting_agency_id = provider_id"
  end

  def self.down
    remove_column :allocations, :reporting_agency_id
  end
end
