class FundingSource < ActiveRecord::Base
  has_many :projects
  has_many :allocations, :through => :projects
  
  validates_presence_of :funding_source_name
  validates_uniqueness_of :funding_subsource_name, :scope => :funding_source_name

  scope :default_order, order(:funding_source_name, :funding_subsource_name)

  def name
    if funding_subsource_name.present?
      "#{funding_source_name}: #{funding_subsource_name}"
    else
      funding_source_name
    end
  end
end
