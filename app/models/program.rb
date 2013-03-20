class Program < ActiveRecord::Base
  has_many :allocations

  validates :name, :presence => true, :uniqueness => true
  
  scope :default_order, :order => :name
end
