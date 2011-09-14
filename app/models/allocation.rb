class Allocation < ActiveRecord::Base
  has_many :trips
  belongs_to :provider
  belongs_to :project
  
  validates :name, :presence => true
  
  self.per_page = 30

  default_scope :order => :name

  def to_s
    name
  end

  def agency
    provider.try :agency
  end

  def funding_source
    return project.funding_source
  end

  def funding_subsource
    return project.funding_subsource
  end

  def project_number
    return project.project_number
  end

  def project_name
    project.try :name
  end

  scope :spd, includes(:project).where(:projects => {:funding_source => 'SPD'})

end
