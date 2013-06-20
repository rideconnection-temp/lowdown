class FlexReport < ActiveRecord::Base
  belongs_to :report_category

  validates :name, :presence => true, :uniqueness => true
  validates_date :start_date, :end_date, :allow_blank => true

  attr_accessor :is_new
  attr_accessor :allocation_objects
  attr_accessor :report_rows
  attr_reader   :results

  TimePeriods = %w{semimonth month quarter year}

  GroupBys = %w{county,quarter funding_source,quarter funding_source,funding_subsource,quarter project_number,quarter funding_source,reporting_agency_name program_name,reporting_agency_name reporting_agency_name,program_name quarter,month}.sort

  GroupMappings = {
    "county"                        => "County",
    "funding_source"                => "Funding Source",
    "funding_subsource"             => "Funding Subsource",
    "funding_source_and_subsource"  => "Funding Source and Subsource",
    "allocation_name"               => "Allocation Name",
    "program_name"                  => "Program Name",
    "project_name"                  => "F.E. Project Name",
    "project_number"                => "F.E. Project Number",
    "provider_name"                 => "Provider Name",
    "reporting_agency_name"         => "Reporting Agency Name",
    "trimet_program_name"           => "TriMet Program Name",
    "trimet_program_identifier"     => "TriMet Program Identifier",
    "trimet_provider_name"          => "TriMet Provider Name",
    "trimet_provider_identifier"    => "TriMet Provider Identifier",
    "trimet_report_group_name"      => "TriMet Report Group Name",
    "semimonth"                     => "Semi-month",
    "month"                         => "Month",
    "quarter"                       => "Quarter",
    "year"                          => "Year"
  }

  def self.new_from_params(params)
    report = self.new(params[:flex_report])

    report.field_list      ||= ''
    report.allocation_list ||= ''

    report
  end

  # Apply the specified block to the leaves of a nested hash (leaves
  # are defined as elements {depth} levels deep, so that hashes
  # can be leaves)
  def self.apply_to_leaves!(group, depth, &block) 
    if depth == 0
      return block.call group
    else
      group.each do |k, v|
        group[k] = FlexReport.apply_to_leaves! v, depth - 1, &block
      end
      return group
    end
  end

  def funding_subsource_names
    if funding_subsource_name_list.blank?
      [""]
    else
      funding_subsource_name_list.split("|")
    end
  end

  def funding_subsource_names=(list)
    if list.blank? 
      self.funding_subsource_name_list = nil
    else
      self.funding_subsource_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def programs
    program_list.blank? ? [] : Program.find_all_by_id(program_list.split(",").map(&:to_i))
  end

  def program_ids
    program_list.blank? ? [""] : program_list.split(",").map(&:to_i)
  end

  def programs=(list)
    if list.blank?
      self.program_list = nil
    else
      self.program_list = list.sort.map(&:to_s).join(",")
    end
  end

  def county_names
    if county_name_list.blank?
      [""]
    else
      county_name_list.split("|")
    end
  end

  def county_names=(list)
    if list.blank? 
      self.county_name_list = nil
    else
      self.county_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def reporting_agencies
    reporting_agency_list.blank? ? [] : Provider.find_all_by_id(reporting_agency_list.split(",").map(&:to_i))
  end

  def reporting_agency_ids
    reporting_agency_list.blank? ? [""] : reporting_agency_list.split(",").map(&:to_i)
  end

  def reporting_agencies=(list)
    if list.blank?
      self.reporting_agency_list = nil
    else
      self.reporting_agency_list = list.sort.map(&:to_s).join(",")
    end
  end

  def providers
    provider_list.blank? ? [] : Provider.find_all_by_id(provider_list.split(",").map(&:to_i))
  end

  def provider_ids
    provider_list.blank? ? [""] : provider_list.split(",").map(&:to_i)
  end

  def providers=(list)
    if list.blank?
      self.provider_list = nil
    else
      self.provider_list = list.sort.map(&:to_s).join(",")
    end
  end

  def allocations
    allocation_list.blank? ? [] : Allocation.find_all_by_id(allocation_list.split(",").map(&:to_i))
  end

  def allocation_ids
    allocation_list.blank? ? [] : allocation_list.split(",").map(&:to_i)
  end

  def allocations=(list)
    if list.blank?
      self.allocation_list = ''
    else
      self.allocation_list = list.sort.map(&:to_s).join(",")
    end
  end

  def fields
    if field_list
      return field_list.split(",")
    else
      return []
    end
  end

  def fields=(list)    
    return self.field_list = '' if list.to_s.empty?

    list = list.keys if list.respond_to?(:keys)
    self.field_list = list.sort.map(&:to_s).join(",")
  end

  def query_end_date
    Date.new(end_date.year, end_date.month, 1) + 1.months
  end
  
  def group_fields
    group_by.split(",")
  end

  # Based on the flex report definition, collect all the actual allocations for which data needs to be gathered.
  # If there are time periods, then take each allocation and break it into the requested time periods
  def collect_allocation_objects!
    where_strings = []
    where_params = []

    where_strings << "do_not_show_on_flex_reports = false"

    where_strings << "(inactivated_on IS NULL OR inactivated_on > ?) AND activated_on < ?"
    where_params.concat [start_date, query_end_date]
    
    if funding_subsource_name_list.present?
      where_strings << "project_id IN (SELECT id FROM projects where COALESCE(funding_source,'') || ': ' || COALESCE(funding_subsource) IN (?))"
      where_params << funding_subsource_names
    end
    if reporting_agency_list.present? 
      where_strings << "reporting_agency_id IN (?)"
      where_params << reporting_agency_ids
    end
    if provider_list.present? 
      where_strings << "provider_id IN (?)"
      where_params << provider_ids
    end
    if program_list.present?
      where_strings << "program_id IN (?)"
      where_params << program_ids
    end
    if county_name_list.present?
      where_strings << "county IN (?)"
      where_params << county_names
    end

    if where_strings.present?
      where_string = where_strings.join(" AND ")
      if allocations.present?
        where_string = "(#{where_string}) OR allocations.id IN (?)"
        where_params << allocations
      end
    elsif allocations.present?
        where_string = "allocations.id IN (?)"
        where_params << allocations
    end
    results = Allocation.where(where_string, *where_params)

    TimePeriods.each do |period|
      if group_fields.member? period
        # only apply the shortest time period if there are multiple time period grouping levels
        results = PeriodAllocation.apply_periods(results, start_date, query_end_date, period)
        break
      end
    end
    @allocation_objects = results
  end
  
  # Gather the data for the selected allocations
  def collect_report_data!
    @report_rows = {}
    options = {}
    options[:pending] = pending
    options[:elderly_and_disabled_only] = elderly_and_disabled_only

    @allocation_objects.each do |allocation_object|
      if allocation_object.respond_to? :collection_start_date 
        collection_start_date = allocation_object.collection_start_date
        collection_end_date = allocation_object.collection_end_date
      else
        collection_start_date = start_date
        collection_end_date = query_end_date
      end

      row = ReportRow.new fields
      row.allocation = allocation_object

      if allocation_object.trip_collection_method == 'trips'
        row.collect_trips_by_trip(allocation_object, collection_start_date, collection_end_date, options)
      else
        row.collect_trips_by_summary(allocation_object, collection_start_date, collection_end_date, options)
      end

      if allocation_object.run_collection_method == 'trips' 
        row.collect_runs_by_trip(allocation_object, collection_start_date, collection_end_date, options)
      elsif allocation_object.run_collection_method == 'runs'
        row.collect_runs_by_run(allocation_object, collection_start_date, collection_end_date, options)
      else
        row.collect_runs_by_summary(allocation_object, collection_start_date, collection_end_date, options)
      end

      if allocation_object.cost_collection_method == 'summary'
        row.collect_costs_by_summary(allocation_object, collection_start_date, collection_end_date, options)
      end
      row.collect_costs_by_trip(allocation_object, collection_start_date, collection_end_date, options)

      row.collect_operation_data_by_summary(allocation_object, collection_start_date, collection_end_date, options)

      row.calculate_total_elderly_and_disabled_cost if elderly_and_disabled_only

      @report_rows[allocation_object] = row
    end
  end

  # Group data into nested sets.  Merge report row objects at the finest group level.
  def group_report_rows!
    grouped_rows = Allocation.group(group_fields, @report_rows.keys)
    FlexReport.apply_to_leaves! grouped_rows, group_fields.size do | allocationset |
      row = ReportRow.new fields
      row.allocation = allocationset[0]
      allocationset.each do |allocation|
        row.include_row(@report_rows[allocation])
      end
      row
    end
    @results = grouped_rows
  end

  # Convenience function for running a flex report from a saved definition.
  def populate_results!
    collect_allocation_objects!
    collect_report_data!
    group_report_rows!
  end
end
