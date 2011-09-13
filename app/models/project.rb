class Project < ActiveRecord::Base
  has_many :allocations
  
  validates :name, :presence => true

  default_scope :order => :name
end
