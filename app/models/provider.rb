class Provider < ActiveRecord::Base
  has_many :allocations
  has_many :summaries
  
  validates :name, :presence => true
end
