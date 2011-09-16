class Provider < ActiveRecord::Base
  has_many :allocations, :order => :name
  has_many :summaries
  
  validates :name, :presence => true

  default_scope :order => :name

  def non_trip_allocations
    allocations.non_trip_collection_method
  end
end
