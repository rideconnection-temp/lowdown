class Allocation < ActiveRecord::Base
  has_many :trips
  has_many :summaries
  belongs_to :provider
  belongs_to :reporting_agency, class_name: "Provider", foreign_key: :reporting_agency_id
  belongs_to :project
  belongs_to :trimet_provider
  belongs_to :trimet_program
  belongs_to :override
  belongs_to :program
  belongs_to :service_type

  DATA_OPTIONS = %w( Prohibited Required )
  SHORT_COUNTY_NAMES = {'Multnomah'=>'Mult','Clackamas'=>'Clack','Washington'=>'Wash'}
  ELIGIBILITIES = ['Elderly & Disabled','Unrestricted','Not Applicable']

  validates :name, presence: true
  validates :admin_ops_data, inclusion: { in: DATA_OPTIONS }
  validates :vehicle_maint_data, inclusion: { in: DATA_OPTIONS }
  validate  :require_consistent_trimet_fields
  validate  :require_consistent_provider_fields
  validates_date :activated_on
  validates_date :inactivated_on, allow_blank: true, after: :activated_on, after_message: "must be after the first day activated"
  self.per_page = 30
  validate do |rec|
    if Allocation.active_on(rec.activated_on).where("id<>?",rec.id || 0).where(name: rec.name).exists?
      rec.errors.add :name, "has already been taken"
    end
    if rec.override_id.present? && rec.routematch_provider_code.present?
      if Allocation.active_on(rec.activated_on).where("id<>?",rec.id || 0).where(override_id: rec.override_id, routematch_provider_code: rec.routematch_provider_code).exists?
        rec.errors.add :override_id, "and provider code have already been taken"
      end
    end
  end

  scope :trip_collection_method, -> { where "trip_collection_method = 'trips' or run_collection_method = 'trips' or cost_collection_method = 'trips'" }
  scope :summary_collection_method, -> { where "trip_collection_method = 'summary' or run_collection_method = 'summary' or cost_collection_method = 'summary' or admin_ops_data = 'Required' or vehicle_maint_data = 'Required'" }
  scope :not_vehicle_maintenance_only, -> { where "NOT (trip_collection_method = 'none' and run_collection_method = 'none' and cost_collection_method = 'none' and vehicle_maint_data = 'Required')" }
  scope :summary_required, -> { where "trip_collection_method = 'summary' OR run_collection_method = 'summary' OR cost_collection_method = 'summary' OR admin_ops_data = 'Required' or vehicle_maint_data = 'Required'" }
  scope :not_recently_inactivated, -> { where "inactivated_on is null or inactivated_on > current_date - interval '3 months'" }
  scope :active_as_of, lambda{|date| where "inactivated_on IS NULL OR inactivated_on > COALESCE(?,current_date - interval '3 months')", date }
  scope :spd, -> { includes(:project).where(projects: {funding_source: {funding_source_name: 'SPD'}}) }
  scope :active_on, lambda{|date| where("activated_on <= ? AND (inactivated_on IS NULL OR inactivated_on > ?)",date,date)}
  scope :active_in_range, lambda{|start_date,after_end_date| where("(inactivated_on IS NULL OR inactivated_on > ?) AND activated_on < ?", start_date, after_end_date) }
  scope :in_trimet_groupings, -> { where('trimet_program_id IS NOT NULL AND trimet_provider_id IS NOT NULL').includes(:trimet_program,:trimet_provider)}
  scope :has_trimet_provider, -> { where 'trimet_provider_id IS NOT NULL' }
  scope :exclude_vehicle_maint_data_only, -> { where("NOT (trip_collection_method = 'none' AND run_collection_method = 'none' AND cost_collection_method = 'none' AND admin_ops_data = 'Prohibited' AND vehicle_maint_data = 'Required')") }
  scope :exclude_admin_ops_data_only, -> { where("NOT (trip_collection_method = 'none' AND run_collection_method = 'none' AND cost_collection_method = 'none' AND admin_ops_data = 'Required' AND vehicle_maint_data = 'Prohibited')") }
  scope :provider_name_starts_with, lambda{|x| where("provider_id IN (SELECT id FROM providers WHERE name ILIKE ?)", "#{x}%") }
  scope :without_trips_or_summaries, -> { where "NOT EXISTS (SELECT id FROM trips WHERE allocation_id = allocations.id) AND NOT EXISTS (SELECT id FROM summaries WHERE allocation_id = allocations.id)" }

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
  #           'plant' => { 'no' => ['oak'],
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
        group_value = nil if group_value.blank?
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

  def self.member_allocation(a)
    if a.is_a?(Array)
      return a[0]
    elsif a.nil?
      return nil
    else
      Allocation.member_allocation(a[a.keys[0]])
    end
  end

  def self.count_members(group, depth)
    total = 0
    if depth == 0
      return 1
    elsif depth == 1
      return group.count
    else
      group.each do |k, v|
        total = total + Allocation.count_members(v, depth - 1)
      end
      return total
    end
  end

  def to_s
    name
  end

  def allocation_name
    name
  end

  def trip_collection_method_name
    trip_collection_method.split.map(&:capitalize).join(' ')
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
    project.try(:funding_source).try(:funding_source_name)
  end

  def funding_subsource
    project.try(:funding_source).try(:funding_subsource_name)
  end

  def funding_source_and_subsource
    project.try(:funding_source).try(:name)
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

  def project_number_and_name
    "#{project.project_number} #{project.name}" if project.present?
  end

  def short_project_number_and_name
    project.try :project_number
  end

  def provider_name
    provider.try :name
  end

  def short_provider_name
    provider.try :short_name
  end

  def provider_type
    provider.try :provider_type
  end

  def reporting_agency_name
    reporting_agency.try :name
  end

  def reporting_agency_type
    reporting_agency.try :provider_type
  end

  def short_reporting_agency_name
    reporting_agency.try :short_name
  end

  def override_name
    override.try :name
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

  def trip_purpose=(value)
    @trip_purpose = value
  end

  def trip_purpose
    @trip_purpose
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
