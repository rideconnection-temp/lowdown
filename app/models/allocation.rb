class Allocation < ActiveRecord::Base
  has_many :trips
  belongs_to :provider
  belongs_to :project
  
  validates :name, :presence => true
  
  self.per_page = 30

  ShortCountyNames = {'Multnomah'=>'Mult','Clackamas'=>'Clack','Washington'=>'Wash'}

  scope :non_trip_collection_method, where( "trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips'" )
  scope :not_recently_inactivated, where( "inactivated_on is null or inactivated_on > current_date - interval '3 months'")

  def to_s
    name
  end

  def allocation_name
    name
  end

  def short_county
    ShortCountyNames.key?(county) ? ShortCountyNames[county] : county
  end

  def agency
    provider.try :agency
  end

  def funding_source
    project.try :funding_source
  end

  def funding_subsource
    project.try :funding_subsource
  end

  def project_number
    project.try :project_number
  end

  def project_name
    project.try :name
  end

  def provider_name
    provider.try :name
  end

  scope :spd, includes(:project).where(:projects => {:funding_source => 'SPD'})

end
