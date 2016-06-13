class Provider < ActiveRecord::Base
  has_many :allocations, -> { order :name }
  has_many :allocations_as_reporting_agency, 
    -> { order :name }, 
    {
      class_name: "Allocation", 
      foreign_key: :reporting_agency_id
    }
  has_many :summaries

  PROVIDER_TYPES = ["BPA Provider", "Partner", "Ride Connection"]
  
  validates :name, presence: true, uniqueness: true
  validates :short_name, length: { maximum: 10 }

  scope :with_summary_data, -> { where "id in (SELECT provider_id FROM allocations WHERE trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips')" }
  scope :with_trip_data, -> { where "id in (SELECT provider_id FROM allocations WHERE trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips')" }
  scope :with_trip_data_as_reporting_agency, -> { where "id in (SELECT reporting_agency_id FROM allocations WHERE trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips')" }
  scope :for_multnomah_ads, -> { where "id in (SELECT provider_id FROM allocations WHERE project_id = (SELECT id FROM projects WHERE funding_source_id IN (SELECT id FROM funding_sources WHERE funding_source_name = ?)))",'Multnomah ADS' }
  scope :reporting_agencies,        -> { where "id in (SELECT reporting_agency_id from allocations)" }
  scope :providers_in_allocations,  -> { where "id in (SELECT provider_id from allocations)" }
  scope :default_order,             -> { order :name }
  scope :bpa_providers,             -> { where provider_type: 'BPA Provider' }

  def allocations_with_trip_data
    Allocation.where(provider_id: id).trip_collection_method.order(:name)
  end

  def to_s
    name
  end

  def active_trip_allocations
    allocations.trip_collection_method.not_recently_inactivated
  end

  def active_summary_allocations
    allocations.summary_required.not_recently_inactivated
  end

  def active_summary_allocations_as_of(d)
    allocations.summary_required.active_as_of(d)
  end
end
