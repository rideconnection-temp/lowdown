class Project < ActiveRecord::Base
  has_many :allocations
  belongs_to :funding_source
  
  validates :name, :presence => true, :uniqueness => true

  scope :default_order, order(:name)

  def self.funding_source_names
    FundingSource.all.map {|x| x.funding_source_name }.sort.uniq
  end

  def self.funding_subsource_names
    FundingSource.all.map {|x| x.name }.sort.uniq
  end

  def number_and_name
    if project_number.present?
      "#{project_number} - #{name}"
    else
      name
    end
  end
end
