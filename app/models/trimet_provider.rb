class TrimetProvider < ActiveRecord::Base
  has_many :allocations, :order => :name
  
  validates :name, :presence => true, :uniqueness => true
  validates :trimet_identifier, :presence => true, :uniqueness => true

  scope :default_order, order(:name)
end
