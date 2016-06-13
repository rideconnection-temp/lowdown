class Program < ActiveRecord::Base
  has_many :allocations

  validates :name, presence: true, uniqueness: true
  
  scope :default_order,   -> { order :name }
  scope :with_trip_data,  -> { where "id in (SELECT program_id FROM allocations WHERE trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips')" }
end
