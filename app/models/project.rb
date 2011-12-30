class Project < ActiveRecord::Base
  has_many :allocations
  
  validates :name, :presence => true

  default_scope :order => :name

  def self.funding_source_names
    unscoped.select('DISTINCT funding_source').map {|x| x.funding_source}.sort
  end

  def self.funding_subsource_names
    r = unscoped.select('DISTINCT funding_source, funding_subsource')
    r.map {|x| x.funding_source + ': ' + x.funding_subsource}.sort
  end
end
