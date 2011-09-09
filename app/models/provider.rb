class Provider < ActiveRecord::Base
  has_many :allocations, :order => :name
  has_many :summaries
  
  validates :name, :presence => true
end
