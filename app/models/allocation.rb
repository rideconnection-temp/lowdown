class Allocation < ActiveRecord::Base
  has_many :trips
  has_many :summaries
  belongs_to :provider
  belongs_to :project
  
  DATA_OPTIONS = %w( Required Prohibited )
  SHORT_COUNTY_NAMES = {'Multnomah'=>'Mult','Clackamas'=>'Clack','Washington'=>'Wash'}

  validates :name, :presence => true
  validates :admin_ops_data, :inclusion => { :in => DATA_OPTIONS }
  validates :vehicle_maint_data, :inclusion => { :in => DATA_OPTIONS }
  
  self.per_page = 30

  scope :non_trip_collection_method, where( "trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips'" )
  scope :trip_collection_method, where( "trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips'" )
  scope :not_recently_inactivated, where( "inactivated_on is null or inactivated_on > current_date - interval '3 months'")

  def self.program_names
    select('DISTINCT program').where("COALESCE(program,'') <> ''").map {|x| x.program}.sort 
  end

  def self.county_names
    select('DISTINCT county').where("COALESCE(county,'') <> ''").map {|x| x.county}.sort 
  end

  def to_s
    name
  end

  def allocation_name
    name
  end

  def short_county
    SHORT_COUNTY_NAMES.key?(county) ? SHORT_COUNTY_NAMES[county] : county
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
