class Allocation < ActiveRecord::Base
  has_many :trips
  has_many :summaries
  belongs_to :provider
  belongs_to :project
  belongs_to :trimet_provider
  belongs_to :trimet_program
  belongs_to :trimet_report_group
  belongs_to :override
  
  DATA_OPTIONS = %w( Required Prohibited )
  SHORT_COUNTY_NAMES = {'Multnomah'=>'Mult','Clackamas'=>'Clack','Washington'=>'Wash'}

  validates :name, :presence => true, :uniqueness => true
  validates :admin_ops_data, :inclusion => { :in => DATA_OPTIONS }
  validates :vehicle_maint_data, :inclusion => { :in => DATA_OPTIONS }
  validates_uniqueness_of :override_id, :scope => :routematch_provider_code, :message => "and provider code have already been taken", :allow_blank => true
  validate  :require_consistent_trimet_fields
  
  self.per_page = 30

  scope :non_trip_collection_method, where( "trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips'" )
  scope :trip_collection_method, where( "trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips'" )
  scope :not_recently_inactivated, where( "inactivated_on is null or inactivated_on > current_date - interval '3 months'")
  scope :spd, includes(:project).where(:projects => {:funding_source => 'SPD'})

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

  def subcontractor
    provider.try :subcontractor
  end

  private

  def require_consistent_trimet_fields
    unless (trimet_provider_id.present? && trimet_program_id.present?) || 
           (trimet_provider_id.nil? && trimet_program_id.nil?)
      errors.add(:base, "Either both TriMet fields must be filled or both must be left blank.")
    end
  end

end
