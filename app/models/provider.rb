class Provider < ActiveRecord::Base
  has_many :allocations, :order => :name
  has_many :summaries
  
  validates :name, :presence => true
  validates :short_name, :length => { :maximum => 10 }

  default_scope :order => :name

  scope :with_summary_data, where("id in (SELECT provider_id FROM allocations WHERE trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips')")

  def active_non_trip_allocations
    allocations.non_trip_collection_method.not_recently_inactivated
  end
end
