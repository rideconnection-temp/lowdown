class Allocation < ActiveRecord::Base
  has_many :trips
  has_many :summaries
  belongs_to :provider
  belongs_to :reporting_agency, :class_name => "Provider", :foreign_key => :reporting_agency_id
  belongs_to :project
  belongs_to :trimet_provider
  belongs_to :trimet_program
  belongs_to :trimet_report_group
  belongs_to :override
  belongs_to :program
  
  DATA_OPTIONS = %w( Prohibited Required )
  SHORT_COUNTY_NAMES = {'Multnomah'=>'Mult','Clackamas'=>'Clack','Washington'=>'Wash'}
  ELIGIBILITIES = ['Elderly & Disabled','Low Income Commuter','Veteran, Spouse, or Widow','Unrestricted','Not Applicable']

  validates :name, :presence => true
  validates :admin_ops_data, :inclusion => { :in => DATA_OPTIONS }
  validates :vehicle_maint_data, :inclusion => { :in => DATA_OPTIONS }
  validate  :require_consistent_trimet_fields
  validate  :require_consistent_provider_fields
  validates_date :activated_on
  validates_date :inactivated_on, :allow_blank => true, :after => :activated_on, :after_message => "must be after the first day activated"
  self.per_page = 30
  validate do |rec|
    if Allocation.active_on(rec.activated_on).where("id<>?",rec.id || 0).where(:name => rec.name).exists?
      rec.errors.add :name, "has already been taken"
    end
    if rec.override_id.present? && rec.routematch_provider_code.present?
      if Allocation.active_on(rec.activated_on).where("id<>?",rec.id || 0).where(:override_id => rec.override_id, :routematch_provider_code => rec.routematch_provider_code).exists?
        rec.errors.add :override_id, "and provider code have already been taken"
      end
    end
  end

  scope :non_trip_collection_method, where( "trip_collection_method != 'trips' or run_collection_method != 'trips' or cost_collection_method != 'trips'" )
  scope :trip_collection_method, where( "trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips'" )
  scope :not_recently_inactivated, where( "inactivated_on is null or inactivated_on > current_date - interval '3 months'")
  scope :active_as_of, lambda{|date| where( "inactivated_on IS NULL OR inactivated_on > COALESCE(?,current_date - interval '3 months')", date) }
  scope :spd, includes(:project).where(:projects => {:funding_source => 'SPD'})
  scope :active_on, lambda{|date| where("activated_on <= ? AND (inactivated_on IS NULL OR inactivated_on > ?)",date,date)}
  scope :active_in_range, lambda{|start_date,after_end_date| where("(inactivated_on IS NULL OR inactivated_on > ?) AND activated_on < ?", start_date, after_end_date) }
  scope :in_trimet_report_group, where('trimet_report_group_id IS NOT NULL AND trimet_program_id IS NOT NULL AND trimet_provider_id IS NOT NULL')
  def self.for_import
    self.joins(:override).select("allocations.id,overrides.name,allocations.routematch_provider_code,allocations.activated_on,allocations.inactivated_on,allocations.run_collection_method")
  end

  def self.program_names
    select('DISTINCT program').where("COALESCE(program,'') <> ''").map {|x| x.program}.sort 
  end

  def self.county_names
    select('DISTINCT county').where("COALESCE(county,'') <> ''").map {|x| x.county}.sort 
  end

  # group a set of records by a list of fields.  
  # groups is a list of fields to group by
  # records is a list of records
  # the output is a nested hash, with one level for each element of groups
  # for example,
  # groups = [kingdom, edible]
  # records = [platypus, cow, oak, apple, orange, shiitake]
  # output = {'animal' => { 'no' => ['platypus'], 
  #                         'yes' => ['cow'] 
  #                       }, 
  #           'plant' => { 'no' => 'oak'], 
  #                        'yes' => ['apple', 'orange']
  #                       }
  #           'fungus' => { 'yes' => ['shiitake'] }
  #          }
  def self.group(groups, records)
    out = {}
    last_group = groups[-1]

    for record in records
      cur_group = out
      for group in groups
        group_value = record.send(group)
        if group == last_group
          if !cur_group.member? group_value
            cur_group[group_value] = []
          end
        else
          if ! cur_group.member? group_value
            cur_group[group_value] = {}
          end
        end
        cur_group = cur_group[group_value]
      end
      cur_group << record
    end
    return out
  end

  def to_s
    name
  end

  def allocation_name
    name
  end

  def select_label
    if activated_on > Date.today then
      "#{name} (activating #{activated_on})"
    elsif inactivated_on && inactivated_on <= Date.today
      "#{name} (inactivated #{inactivated_on})"
    else
      name
    end
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

  def funding_source_and_subsource
    if funding_subsource.present?
      "#{funding_source}: #{funding_subsource}"
    else
      funding_source
    end
  end

  def program_name
    program.try :name
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

  def reporting_agency_name
    reporting_agency.try :name
  end

  def trimet_program_name
    trimet_program.try :name
  end

  def trimet_program_identifier
    trimet_program.try :trimet_identifier
  end

  def trimet_provider_name
    trimet_provider.try :name
  end

  def trimet_provider_identifier
    trimet_provider.try :trimet_identifier
  end

  def trimet_report_group_name
    trimet_report_group.try :name
  end

  private

  def require_consistent_provider_fields
    unless (provider.present? && reporting_agency.present?) || 
           (provider.nil? && reporting_agency.nil?)
      errors.add(:base, "The provider and reporting agency fields must both be filled or both left blank.")
    end
  end

  def require_consistent_trimet_fields
    unless (trimet_provider_id.present? && trimet_program_id.present?) || 
           (trimet_provider_id.nil? && trimet_program_id.nil?)
      errors.add(:base, "Either both TriMet fields must be filled or both must be left blank.")
    end
  end

  def require_consistent_trimet_fields
    unless (trimet_provider_id.present? && trimet_program_id.present?) || 
           (trimet_provider_id.nil? && trimet_program_id.nil?)
      errors.add(:base, "Either both TriMet fields must be filled or both must be left blank.")
    end
  end

end
