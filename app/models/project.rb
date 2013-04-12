class Project < ActiveRecord::Base
  has_many :allocations
  
  validates :name, :presence => true, :uniqueness => true

  scope :default_order, order(:name)

  def self.funding_source_names
    unscoped.select('DISTINCT funding_source').map {|x| x.funding_source}.sort
  end

  def self.funding_subsource_names
    r = unscoped.select('DISTINCT funding_source, funding_subsource')
    r.map {|x| x.funding_source + ': ' + x.funding_subsource}.sort
  end

  def number_and_name
    if project_number.present?
      "#{project_number} - #{name}"
    else
      name
    end
  end
end
