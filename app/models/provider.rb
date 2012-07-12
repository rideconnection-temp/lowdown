class Provider < ActiveRecord::Base
  has_many :allocations, :order => :name
  has_many :summaries
  
  validates :name, :presence => true
  validates :short_name, :length => { :maximum => 10 }

  scope :with_summary_data, where("id in (SELECT provider_id FROM allocations WHERE trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips')")

  scope :with_trip_data, where("id in (SELECT provider_id FROM allocations WHERE trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips')")
  scope :for_multnomah_ads, where("id in (SELECT provider_id FROM allocations WHERE project_id = (SELECT id FROM projects WHERE funding_source = ?))",'Multnomah ADS')
  scope :default_order, order(:name,:subcontractor)

  def self.subcontractor_names
    self.select("DISTINCT subcontractor").where("COALESCE(subcontractor,'') <> ''").order(:subcontractor).map {|p| p.subcontractor}
  end

  def to_s
    if subcontractor == name
      name
    else
      name << (subcontractor.present? ? " (by #{subcontractor})" : "")
    end
  end

  def active_trip_allocations
    allocations.trip_collection_method.not_recently_inactivated
  end

  def active_non_trip_allocations
    allocations.non_trip_collection_method.not_recently_inactivated
  end
end
