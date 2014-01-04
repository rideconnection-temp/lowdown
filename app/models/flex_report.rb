class FlexReport < ActiveRecord::Base
  belongs_to :report_category

  validates :name, :presence => true, :uniqueness => true
  validates_date :start_date, :end_date, :allow_blank => true
  validates_date :end_month

  attr_accessor :is_new
  attr_accessor :allocation_objects
  attr_accessor :report_rows
  attr_reader   :results
  columns_hash["end_month"] = ActiveRecord::ConnectionAdapters::Column.new("end_month", nil, "date")

  TimePeriods = %w{semimonth month quarter year}

  GroupBys = [
    "county,quarter",
    "funding_source,quarter",
    "funding_source,funding_subsource,quarter",
    "project_number,quarter",
    "funding_source,reporting_agency_name",
    "program_name,reporting_agency_name",
    "reporting_agency_name,program_name",
    "quarter,month"
  ].sort

  GroupMappings = {
    "county"                        => "County",
    "funding_source"                => "Funding Source",
    "funding_subsource"             => "Funding Subsource",
    "funding_source_and_subsource"  => "Funding Source and Subsource",
    "override_name"                 => "Override Name",
    "allocation_name"               => "Allocation Name",
    "program_name"                  => "Program Name",
    "project_name"                  => "F.E. Project Name",
    "project_number"                => "F.E. Project Number",
    "project_number_and_name"       => "F.E. Project Number and Name",
    "provider_name"                 => "Provider Name",
    "provider_type"                 => "Provider Type",
    "reporting_agency_name"         => "Reporting Agency Name",
    "reporting_agency_type"         => "Reporting Agency Type",
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

  def end_month
    Date.new(end_date.year, end_date.month, 1) if end_date.present?
  end

  def end_month=(value)
    self.end_date = Date.new(value.year,value.month,1) + 1.month - 1.day
  end

  def after_end_date
    end_date + 1.day if end_date.present?
  end
  
  def projects
    project_list.blank? ? [] : Project.find_all_by_id(project_list.split(",").map(&:to_i))
  end

  def project_ids
    project_list.blank? ? [""] : project_list.split(",").map(&:to_i)
  end

  def projects=(list)
    if list.blank?
      self.project_list = nil
    else
      self.project_list = list.sort.map(&:to_s).join(",")
    end
  end

  def funding_sources
    funding_source_list.blank? ? [] : FundingSource.find_all_by_id(funding_source_list.split(",").map(&:to_i))
  end

  def funding_source_ids
    funding_source_list.blank? ? [""] : funding_source_list.split(",").map(&:to_i)
  end

  def funding_sources=(list)
    if list.blank?
      self.funding_source_list = nil
    else
      self.funding_source_list = list.sort.map(&:to_s).join(",")
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

  def reporting_agency_type_names
    if reporting_agency_type_name_list.blank?
      [""]
    else
      reporting_agency_type_name_list.split("|")
    end
  end

  def reporting_agency_type_names=(list)
    if list.blank? 
      self.reporting_agency_type_name_list = nil
    else
      self.reporting_agency_type_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
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

  def provider_type_names
    if provider_type_name_list.blank?
      [""]
    else
      provider_type_name_list.split("|")
    end
  end

  def provider_type_names=(list)
    if list.blank? 
      self.provider_type_name_list = nil
    else
      self.provider_type_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
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
    allocation_list.blank? ? [""] : allocation_list.split(",").map(&:to_i)
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

  def group_fields
    group_by.split(",")
  end

  # Based on the flex report definition, collect all the actual allocations for which data needs to be gathered.
  # If there are time periods, then take each allocation and break it into the requested time periods
  def collect_allocation_objects!(allocation_instance = Allocation)
    where_strings = []
    where_params = []

    where_strings << "do_not_show_on_flex_reports = false"

    where_strings << "(inactivated_on IS NULL OR inactivated_on > ?) AND activated_on < ?"
    where_params.concat [start_date, after_end_date]
    
    if funding_source_list.present?
      where_strings << "project_id IN (SELECT id FROM projects WHERE funding_source_id IN (?))"
      where_params << funding_source_ids
    end
    if project_list.present?
      where_strings << "project_id IN (?)"
      where_params << project_ids
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
    if reporting_agency_type_name_list.present?
      where_strings << "reporting_agency_id IN (SELECT id FROM providers WHERE provider_type IN (?))"
      where_params << reporting_agency_type_names 
    end
    if provider_type_name_list.present?
      where_strings << "provider_id IN (SELECT id FROM providers WHERE provider_type IN (?))"
      where_params << provider_type_names 
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
    results = allocation_instance.where(where_string, *where_params)

    TimePeriods.each do |period|
      if group_fields.member? period
        # only apply the shortest time period if there are multiple time period grouping levels
        results = PeriodAllocation.apply_periods(results, start_date, after_end_date, period)
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
        collection_after_end_date = allocation_object.collection_after_end_date
      else
        collection_start_date = start_date
        collection_after_end_date = after_end_date
      end

      row = ReportRow.new fields, allocation_object

      if allocation_object.trip_collection_method == 'trips'
        row.collect_trips_by_trip(allocation_object, collection_start_date, collection_after_end_date, options)
      else
        row.collect_trips_by_summary(allocation_object, collection_start_date, collection_after_end_date, options)
      end

      if allocation_object.run_collection_method == 'trips' 
        row.collect_runs_by_trip(allocation_object, collection_start_date, collection_after_end_date, options)
      elsif allocation_object.run_collection_method == 'runs'
        row.collect_runs_by_run(allocation_object, collection_start_date, collection_after_end_date, options)
      else
        row.collect_runs_by_summary(allocation_object, collection_start_date, collection_after_end_date, options)
      end

      if allocation_object.cost_collection_method == 'summary'
        row.collect_costs_by_summary(allocation_object, collection_start_date, collection_after_end_date, options)
      end
      row.collect_costs_by_trip(allocation_object, collection_start_date, collection_after_end_date, options)

      row.collect_operation_data_by_summary(allocation_object, collection_start_date, collection_after_end_date, options)

      row.calculate_total_elderly_and_disabled_cost if elderly_and_disabled_only

      @report_rows[allocation_object] = row
    end
  end

  # Gather the data for the selected allocations
  def collect_report_data_quickly!
    options = {}
    options[:pending] = pending
    
    @report_rows = {}
    @allocation_objects.each do |ao|
      row = ReportRow.new fields, ao
      @report_rows[ao] = row
    end

    if elderly_and_disabled_only
      ed_handling_values = [
        {:filter_trips_for_ed_only => false, :allocations => :ed}, 
        {:filter_trips_for_ed_only => true,  :allocations => :non_ed}
      ]
    else
      ed_handling_values = [
        {:filter_trips_for_ed_only => false, :allocations => :all}
      ]
    end

    date_ranges = []
    if (TimePeriods & group_fields).size > 0
      @allocation_objects.each do |ao|
        this_date_range = {:start_date => ao.collection_start_date, :after_end_date => ao.collection_after_end_date}
        date_ranges << this_date_range unless date_ranges.include?(this_date_range)
      end
    else
      date_ranges << {:start_date => start_date, :after_end_date => after_end_date}
    end

    date_ranges.each do |date_range|
      ed_handling_values.each do |ed_handling|
        options[:elderly_and_disabled_only] = ed_handling[:filter_trips_for_ed_only]
        if ed_handling[:allocations] == :ed
          allocation_group = @allocation_objects.select{|ao| ao.eligibility == 'Elderly & Disabled'}
        elsif ed_handling[:allocations] == :non_ed
          allocation_group = @allocation_objects.select{|ao| ao.eligibility != 'Elderly & Disabled'}
        else
          allocation_group = @allocation_objects
        end
        collect_report_data_group allocation_group, 
                                  date_range[:start_date], 
                                  date_range[:after_end_date],
                                  options
      end
    end
  end

  def collect_report_data_group(this_start_date, this_after_end_date, options)
    these_allocations = @allocation_objects.select{|ao| ao.trip_collection_method == 'trips'}
    if these_allocations.present?
      collect_all_trips_by_trip(these_allocations, this_start_date, this_after_end_date, options) 
    end

    these_allocations = @allocation_objects.select{|ao| ao.trip_collection_method != 'trips'}
    if these_allocations.present?
      collect_all_trips_by_summary(these_allocations, this_start_date, this_after_end_date, options) 
    end

    these_allocations = @allocation_objects.select{|ao| ao.run_collection_method == 'trips'}
    if these_allocations.present?
      collect_all_runs_by_trip(these_allocations, this_start_date, this_after_end_date, options) 
    end

    these_allocations = @allocation_objects.select{|ao| ao.run_collection_method == 'runs'}
    if these_allocations.present?
      collect_all_runs_by_run(these_allocations, this_start_date, this_after_end_date, options) 
    end

    if these_allocations.present?
      collect_all_runs_by_summary(these_allocations, this_start_date, this_after_end_date, options) 
    end

    these_allocations = @allocation_objects.select{|ao| ao.cost_collection_method == 'summary'}
    if these_allocations.present?
      collect_all_costs_by_summary(these_allocations, this_start_date, this_after_end_date, options) 
    end

    collect_all_costs_by_trip(@allocation_objects, this_start_date, this_after_end_date, options)

    collect_all_operation_data_by_summary(@allocation_objects, this_start_date, this_after_end_date, options)

    calculate_total_elderly_and_disabled_cost if elderly_and_disabled_only
  end

  # Group data into nested sets.  Merge report row objects at the finest group level.
  def group_report_rows!
    grouped_rows = Allocation.group(group_fields, @report_rows.keys)
    FlexReport.apply_to_leaves! grouped_rows, group_fields.size do | allocationset |
      row = ReportRow.new fields, allocationset[0]
      allocationset.each do |allocation|
        row.include_row(@report_rows[allocation])
      end
      row
    end
    @results = grouped_rows
  end

  # Convenience function for running a flex report from a saved definition.
  def populate_results!(allocation_instance = Allocation)
    collect_allocation_objects!(allocation_instance)
    collect_report_data!
    group_report_rows!
  end

  def collect_all_trips_by_trip(allocations, start_date, after_end_date, options = {})
    select = "
      allocation_id, 
      SUM(
        CASE WHEN in_trimet_district=true AND result_code = 'COMP' 
        THEN 1 + guest_count + attendant_count 
        ELSE 0 
        END) AS in_district_trips, 
      SUM(
        CASE WHEN in_trimet_district=false AND result_code = 'COMP' 
        THEN 1 + guest_count + attendant_count 
        ELSE 0 
        END) AS out_of_district_trips, 
      SUM(
        CASE WHEN result_code = 'COMP' 
        THEN 1 
        ELSE 0 
        END) AS customer_trips, 
      SUM(
        CASE WHEN result_code = 'COMP' 
        THEN guest_count + attendant_count 
        ELSE 0 
        END) AS guest_and_attendant_trips, 
      SUM(
        CASE WHEN result_code='TD' 
        THEN 1 + guest_count + attendant_count 
        ELSE 0 
        END) AS turn_downs"
    results = Trip.select(select).group(:allocation_id)
    results = results.where(:allocation_id => allocations.map{|a| a.id})
    results = results.current_versions.date_range(start_date, after_end_date)
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] 

    # TODO: replace this: apply_results(add_results)

    # Collect the total_general_public_trips only if we're dealing with a service that's 
    # not strictly for elderly and disabled customers.
    # This will be used to create a ratio of E&D to total trips 
    # so that we can calculate costs for the TriMet E&D report.
    if options[:elderly_and_disabled_only] 
      select = "
        allocation_id, 
        SUM(
          CASE WHEN result_code = 'COMP' 
          THEN 1 + guest_count + attendant_count 
          ELSE 0 
          END) AS total_general_public_trips"
      results = Trip.select(select).group(:allocation_id)
      results = results.where(:allocation_id => allocations.map{|a| a.id})
      results = results.current_versions.date_range(start_date, after_end_date)
      results = results.data_entry_complete unless options[:pending]

      # TODO: replace this: apply_results(add_results)
    end
  end

  def collect_all_trips_by_summary(allocations, start_date, after_end_date, options = {})
    unless options[:elderly_and_disabled_only] 
      select = "allocation_id,
                SUM(in_district_trips) AS in_district_trips, 
                SUM(out_of_district_trips) AS out_of_district_trips"
      results = Summary.select(select).group(:allocation_id)
      results = results.where(:allocation_id => allocations.map{|a| a.id}).joins(:summary_rows)
      results = results.current_versions.date_range(start_date, after_end_date)
      results = results.data_entry_complete unless options[:pending]

      # TODO: replace this: apply_results(add_results)
    end

    unless options[:elderly_and_disabled_only] 
      select = "allocation_id, 
                SUM(turn_downs) AS turn_downs, 
                SUM(unduplicated_riders) AS undup_riders"
      results = Summary.select(select).group(:allocation_id)
      results = results.where(:allocation_id => allocations.map{|a| a.id})
      results = results.current_versions.date_range(start_date, after_end_date)
      results = results.data_entry_complete unless options[:pending]

      # TODO: replace this: apply_results(add_results)
    end

    # Collect the total_general_public_trips only if we're dealing with a service that's 
    # not strictly for elderly and disabled customers.  This will be used in the E&D audit export
    if options[:elderly_and_disabled_only] 
      select = "allocation_id, 
                SUM(in_district_trips) + SUM(out_of_district_trips) AS total_general_public_trips"
      results = Summary.select(select).group(:allocation_id)
      results = results.where(:allocation_id => allocations.map{|a| a.id}).joins(:summary_rows)
      results = results.current_versions.date_range(start_date, after_end_date)
      results = results.data_entry_complete unless options[:pending]

      # TODO: replace this: apply_results(add_results)
    end
  end

  def collect_all_runs_by_trip(allocations, start_date, after_end_date, options = {})
    select = "allocation_id, 
              SUM(apportioned_mileage) AS mileage, 
              SUM(
                CASE WHEN COALESCE(volunteer_trip,false)=false 
                THEN apportioned_duration 
                ELSE 0 
                END)/3600.0 AS driver_paid_hours, 
              SUM(
                CASE WHEN volunteer_trip=true 
                THEN apportioned_duration 
                ELSE 0 
                END)/3600.0 AS driver_volunteer_hours, 
              0 AS escort_volunteer_hours"
    results = Trip.select(select).group(:allocation_id)
    results = results.completed.where(:allocation_id => allocations.map{|a| a.id})
    results = results.current_versions.date_range(start_date, after_end_date)
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]

    # TODO: replace: apply_results(add_results)
  end

  def collect_all_runs_by_run(allocations, start_date, after_end_date, options = {})
    select = "allocation_id,
              SUM(apportioned_mileage) AS mileage, 
              SUM(
                CASE WHEN COALESCE(volunteer_trip,false)=false 
                THEN apportioned_duration 
                ELSE 0 
                END)/3600.0 AS driver_paid_hours, 
              SUM(
                CASE WHEN volunteer_trip=true 
                THEN apportioned_duration 
                ELSE 0 
                END)/3600.0 AS driver_volunteer_hours, 
              SUM(COALESCE((
                SELECT escort_count 
                FROM runs 
                WHERE id = trips.run_id
                ),0) * apportioned_duration)/3600.0 AS escort_volunteer_hours"
    results = Trip.select(select).group(:allocation_id)
    results = results.completed.where(:allocation_id => allocations.map{|a| a.id})
    results = results.current_versions.date_range(start_date, after_end_date)
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]

    # TODO: replace: apply_results(add_results)
  end

  def collect_all_runs_by_summary(allocations, start_date, after_end_date, options = {})
    unless options[:elderly_and_disabled_only]
      select = "allocation_id,
                SUM(total_miles) AS mileage, 
                SUM(driver_hours_paid) AS driver_paid_hours, 
                SUM(driver_hours_volunteer) AS driver_volunteer_hours, 
                SUM(escort_hours_volunteer) AS escort_volunteer_hours"
      results = Summary.select(select).group(:allocation_id)
      results = results.where(:allocation_id => allocations.map{|a| a.id})
      results = results.current_versions.date_range(start_date, after_end_date)
      results = results.data_entry_complete unless options[:pending]

      # TODO: replace: apply_results(add_results)
    end
  end

  def collect_all_costs_by_trip(allocations, start_date, after_end_date, options = {})
    select = "allocation_id,
              SUM(apportioned_fare) AS funds, 
              0 AS agency_other, 
              0 AS donations"
    results = Trip.select(select).group(:allocation_id)
    results = results.where(:allocation_id => allocations.map{|a| a.id})
    results = results.current_versions.date_range(start_date, after_end_date)
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]

    # TODO: replace: apply_results(add_results)

    # Collect the total_general_public_cost only if we're dealing with a service that's 
    # not strictly for elderly and disabled customers. This is used for audit purposes.
    if options[:elderly_and_disabled_only]
      select = "allocation_id,
                SUM(apportioned_fare) AS total_general_public_cost"
      results = Trip.select(select).group(:allocation_id)
      results = results.where(:allocation_id => allocations.map{|a| a.id})
      results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
      results = results.data_entry_complete unless options[:pending]

      # TODO: replace: apply_results(add_results)
    end

  end

  def collect_all_costs_by_summary(allocations, start_date, after_end_date, options = {})
    select = "allocation_id,
              SUM(funds) AS funds, 
              SUM(agency_other) AS agency_other, 
              SUM(donations) AS donations"
    results = Summary.select(select).group(:allocation_id)
    results = results.where(:allocation_id => allocations.map{|a| a.id})
    results = results.current_versions.date_range(start_date, after_end_date)
    results = results.data_entry_complete unless options[:pending]

    # TODO: replace: apply_results(add_results)
  end

  def collect_all_operation_data_by_summary(allocations, start_date, after_end_date, options = {})
    unless options[:elderly_and_disabled_only]
      select = "allocation_id, 
                SUM(operations) AS operations, 
                SUM(administrative) AS administrative, 
                SUM(vehicle_maint) AS vehicle_maint, 
                SUM(administrative_hours_volunteer) AS admin_volunteer_hours"
      results = Summary.select(select).group(:allocation_id)
      results = results.where(:allocation_id => allocations.map{|a| a.id})
      results = results.current_versions.date_range(start_date, after_end_date)
      results = results.data_entry_complete unless options[:pending]

      # TODO: replace: apply_results(add_results)
    end
  end

end
