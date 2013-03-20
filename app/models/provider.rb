class Provider < ActiveRecord::Base
  has_many :allocations, :order => :name
  has_many :allocations_as_reporting_agency, :class_name => "Allocation", 
               :foreign_key => :reporting_agency_id, :order => :name
  has_many :summaries

  PROVIDER_TYPES = ["BPA Provider", "Partner", "Ride Connection"]
  
  validates :name, :presence => true, :uniqueness => true
  validates :short_name, :length => { :maximum => 10 }

  scope :with_summary_data, where("id in (SELECT provider_id FROM allocations WHERE trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips')")

  scope :with_trip_data, where("id in (SELECT provider_id FROM allocations WHERE trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips')")
  scope :for_multnomah_ads, where("id in (SELECT provider_id FROM allocations WHERE project_id = (SELECT id FROM projects WHERE funding_source = ?))",'Multnomah ADS')
  scope :partners, where(:provider_type => "Partner")
  scope :partners_or_current, lambda{|provider_id| where(["provider_type = ? OR id = ?", "Partner", provider_id])}
  scope :reporting_agencies, where("id in (SELECT reporting_agency_id from allocations)")
  scope :providers_in_allocations, where("id in (SELECT provider_id from allocations)")
  scope :default_order, order(:name)

  def to_s
    name
  end

  def active_trip_allocations
    allocations.trip_collection_method.not_recently_inactivated
  end

  def active_non_trip_allocations
    allocations.non_trip_collection_method.not_recently_inactivated
  end
end
