class Project < ActiveRecord::Base
  has_many :allocations
  
  validates :name, :presence => true
end
