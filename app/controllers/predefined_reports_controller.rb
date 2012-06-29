class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date, :end_date, :after_end_date

  def initialize(params = {})
    now = Date.today
    if params[:start_date]
      @start_date = params[:start_date].to_date
    else
      @start_date = Date.new(now.year, now.month, 1).prev_month
    end
    if params[:end_date]
      @end_date = params[:end_date].to_date
      @after_end_date = @end_date + 1.day
    else
      @after_end_date = start_date.next_month
      @end_date = @after_end_date - 1.day
    end
  end

  def persisted?
    false
  end
end

class PredefinedReportsController < ApplicationController
  
  def index
    @query = Query.new

  end

  def show_create_quarterly
    if params[:report].blank? || params[:report][:start_date].blank? || params[:report][:end_date].blank?
      quarter_start = Date.new(Date.today.year, (Date.today.month-1)/3*3+1,1)
      params[:report] = {}
      params[:report][:start_date] = quarter_start - 3.months
      params[:report][:end_date] = quarter_start - 1.months
    end
    @report = FlexReport.new(params[:report])
  end
  
  def spd_report
    @query = Query.new(params[:query])
    trips = Trip.current_versions.completed.spd.date_range(@query.start_date,@query.after_end_date).includes(:customer)

    @spd_offices = {}
    @customer_rows = {}
    @approved_rides = 0
    @wc_billed_rides = @nonwc_billed_rides = @unknown_billed_rides = 0
    @wc_mileage = @nonwc_mileage = @unknown_mileage = 0

    for trip in trips
      row_key = [trip.customer_id, trip.wheelchair?]
      customer = trip.customer
      office_key = trip.case_manager_office
      @customer_rows[office_key] = {} unless @customer_rows.has_key?(office_key)

      row = @customer_rows[office_key][row_key]
      if row.nil?
        row = {:customer          => customer,
               :billed_rides      => 0, 
               :billable_mileage  => 0, 
               :mobility          => trip.wheelchair?,
               :date_enrolled     => trip.date_enrolled,
               :service_end       => trip.service_end,
               :approved_rides    => trip.approved_rides,
               :case_manager      => trip.case_manager}
        @customer_rows[office_key][row_key] = row
      end

      row[:billed_rides] += 1
      row[:billable_mileage] += trip.spd_mileage

      @approved_rides += trip.approved_rides.to_i
      if trip.wheelchair?.nil?
        @unknown_billed_rides += 1
        @unknown_mileage += trip.spd_mileage
      elsif trip.wheelchair?
        @wc_billed_rides += 1
        @wc_mileage += trip.spd_mileage
      else
        @nonwc_billed_rides += 1
        @nonwc_mileage += trip.spd_mileage
      end
    end
  end

  def show_ride_purpose_report
    @start_date = start_month_from_params params[:ride_purpose_query]
  end

  def ride_purpose_report
    @start_date = start_month_from_params params[:ride_purpose_query]
    @end_date   = @start_date.next_month

    results = Allocation.all
    group_fields = ["county", "provider"]
    allocations = group(group_fields, results)
    @counties = {}
    for county, rows in allocations
      @counties[county] = {}
      for provider, allocations in rows
        row = @counties[county][provider] = RidePurposeRow.new
        for allocation in allocations
          if allocation['trip_collection_method'] == 'trips'
            row.collect_by_trip(allocation, @start_date, @end_date)
          else
            row.collect_by_summary(allocation, @start_date, @end_date)
          end

        end
      end
    end
    @trip_purposes = RidePurposeRow.trip_purposes
  end

  def quarterly_narrative_report
    @report = FlexReport.new(params[:report])
    @report.end_date = @report.end_date + 1.month - 1.day
    allocations = Allocation.find_all_by_provider_id(params[:provider_id]) if params[:provider_id].present?

    groups = "allocations.name,month"
    group_fields = ['allocation_name', 'month']

    do_report(groups, group_fields, @report.start_date, @report.end_date + 1.day, allocations, nil, false, false)

    @quarter     = @report.start_date.month / 3 + 1
    @groups_size = group_fields.size #this might not be necessary
    @allocations = @results
  end

  def show_create_age_and_ethnicity
    @providers = Provider.default_order.map {|x| x.name}.uniq
  end

  def age_and_ethnicity
    @start_date = Date.new(params[:q]["start_date(1i)"].to_i, params[:q]["start_date(2i)"].to_i, 1)
    @provider = params[:q][:provider]

    allocations = Allocation.joins(:provider).where(["providers.name = ? and exists(select id from trips where trips.allocation_id=allocations.id)", @provider])

    if allocations.empty?
      flash[:notice] = "No allocations for this agency/branch"
      return redirect_to :action=>:show_create_age_and_ethnicity
    end

    allocation_ids = allocations.map { |x| x.id }

    undup_riders_sql = "select count(*) as undup_riders, %s from (select customer_id, fiscal_year(date) as year, min(fiscal_month(date)) as month from trips inner join customers on trips.customer_id=customers.id where allocation_id in (?) and valid_end=? and result_code = 'COMP' group by customer_id, year) as customer_ids, customers where year = ? %%s and customers.id=customer_id group by %s"

    #unduplicated by age this month
    undup_riders_age_sql = undup_riders_sql % ["age(customers.birthdate) > interval '60 years' as over60", "over60"]
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_age_sql % "and month = ?", 
                                                          allocation_ids, Trip.end_of_time, 
                                                          @start_date.advance(:months=>6).year, 
                                                          @start_date.advance(:months=>6).month]))

    @current_month_unduplicated_old = @current_month_unduplicated_young = @current_month_unduplicated_unknown = 0
    for row in rows
      if row['over60'] == 't'
        @current_month_unduplicated_old = row['undup_riders'].to_i
      elsif row['over60'] == 'f'
        @current_month_unduplicated_young = row['undup_riders'].to_i
      else
        @current_month_unduplicated_unknown = row['undup_riders'].to_i
      end
    end

    #unduplicated by age ytd
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_age_sql % "",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @start_date.advance(:months=>6).year]))

    @ytd_age_old = @ytd_age_young = @ytd_age_unknown = 0
    for row in rows
      if row['over60'] == 't'
        @ytd_age_old = row['undup_riders'].to_i
      elsif row['over60'] == 'f'
        @ytd_age_young = row['undup_riders'].to_i
      else
        @ytd_age_unknown = row['undup_riders'].to_i
      end
    end

    #now, by ethnicity
    undup_riders_ethnicity_sql = undup_riders_sql % ["race", "race"]
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_ethnicity_sql % "and month = ?",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @start_date.advance(:months=>6).year, 
                                                          @start_date.advance(:months=>6).month]))

    @ethnicity = {}
    for row in rows
      @ethnicity[row["race"] || 'Unknown'] = {"unduplicated" => row['undup_riders']}
    end

    #ethnicity ytd
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_ethnicity_sql % "",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @start_date.advance(:months=>6).year]))

    for row in rows
      race = row["race"] || 'Unknown'
      if ! @ethnicity.member? race
        @ethnicity[race] = {"unduplicated" => 0}
      end
      @ethnicity[race]["ytd"] = row['undup_riders']
    end
  end

  private

  def prep_edit
    @funding_subsource_names  = [['<Select All>','']] + Project.funding_subsource_names
    @providers                = [['<Select All>','']] + Provider.default_order.map {|x| [x.to_s, x.id]}
    @subcontractor_names      = [['<Select All>','']] + Provider.subcontractor_names
    @program_names            = [['<Select All>','']] + Allocation.program_names
    @county_names             = [['<Select All>','']] + Allocation.county_names
    @group_bys = FlexReport::GroupBys.sort
    if @report.group_by.present?
      @group_bys = @group_bys << @report.group_by unless @group_bys.include? @report.group_by
    end
  end


  def start_month_from_params(date_params)
    date_params.present? ? 
      Date.new( date_params["start_date(1i)"].to_i, date_params["start_date(2i)"].to_i, 1 ) : 
      Date.today.at_beginning_of_month - 1.month
  end
  
  # Collect all data, and summarize it grouped according to the groups provided.
  # groups: the names of groupings, in order from coarsest to finest (i.e. project_name, quarter)
  # group_fields: the names of groupings with table names (i.e. projects.name, quarter)
  # allocation: an list of allocations to restrict the report to
  # fields: a list of fields to display

  def do_report(groups, group_fields, start_date, end_date, allocations, fields, pending, adjustment, adjustment_start_date=nil, adjustment_end_date=nil, filters=nil)
    group_select = []

    for group,field in groups.split(",").zip group_fields
      group_select << "#{group} as #{field}"
    end

    group_select = group_select.join(",")

    results = Allocation
    where_strings = []
    where_params = []
    if filters.present?
      if filters.key? :funding_subsource_names
        results = results.joins(:project)
        where_strings << "COALESCE(projects.funding_source,'') || ': ' || COALESCE(projects.funding_subsource) IN (?)"
        where_params << filters[:funding_subsource_names]
      end
      if filters.key?(:provider_ids) 
        where_strings << "provider_id IN (?)"
        where_params << filters[:provider_ids]
      end
      if filters.key? :subcontractor_names
        results = results.joins(:provider)
        where_strings << "providers.subcontractor IN (?)"
        where_params << filters[:subcontractor_names]
      end
      if filters.key? :program_names
        where_strings << "program IN (?)"
        where_params << filters[:program_names]
      end
      if filters.key? :county_names
        where_strings << "county IN (?)"
        where_params << filters[:county_names]
      end
      where_string = where_strings.join(" AND ")
      if allocations.present?
        where_string = "(#{where_string}) OR allocations.id IN (?)"
        where_params << allocations
      end
    elsif allocations.present?
      where_string = "allocations.id IN (?)"
      where_params << allocations
    end
    results = results.where(where_string, *where_params)
     
    for period in @@time_periods
      if group_fields.member? period
        results = PeriodAllocation.apply_periods(results, start_date, end_date, period)
      end
    end

    allocations = group(group_fields, results)
    apply_to_leaves! allocations, group_fields.size do | allocationset |
      row = ReportRow.new fields

      for allocation in allocationset
        if allocation.respond_to? :period_start_date 
          collection_start_date = allocation.period_start_date
          collection_end_date = allocation.period_end_date
        else
          collection_start_date = start_date
          collection_end_date = end_date
          # collection_start_date = adjustment ? adjustment_start_date : start_date
          # collection_end_date   = adjustment ? adjustment_end_date : end_date
        end

        if allocation.trip_collection_method == 'trips'
          row.collect_trips_by_trip(allocation, collection_start_date, collection_end_date, pending, adjustment)
        else
          row.collect_trips_by_summary(allocation, collection_start_date, collection_end_date, pending, adjustment)
        end

        if allocation.run_collection_method == 'trips' 
          row.collect_runs_by_trip(allocation, collection_start_date, collection_end_date, pending, adjustment)
        elsif allocation.run_collection_method == 'runs'
          row.collect_runs_by_run(allocation, collection_start_date, collection_end_date, pending, adjustment)
        else
          row.collect_runs_by_summary(allocation, collection_start_date, collection_end_date, pending, adjustment)
        end

        if allocation.cost_collection_method == 'summary'
          row.collect_costs_by_summary(allocation, collection_start_date, collection_end_date, pending, adjustment)
        end
        row.collect_costs_by_trip(allocation, collection_start_date, collection_end_date, pending, adjustment)

        row.collect_operation_data_by_summary(allocation, collection_start_date, collection_end_date, pending, adjustment)

      end
      row.allocation = allocationset[0]
      row
    end

    @levels = group_fields.size
    @group_fields = group_fields
    @results = allocations
    @start_date = start_date
    @end_date = end_date
    @fields = {}
    if fields.nil? or fields.empty?
      ReportRow.fields.each do |field| 
        @fields[field] = 1
      end
    else
      fields.each do |field| 
        @fields[field] = 1
      end
    end

    @fields['driver_hours'] = 0
    for @field in ['driver_volunteer_hours', 'driver_paid_hours', 'driver_total_hours']
      if @fields.member? field
        @fields['driver_hours'] += 1
      end
    end
    @fields['volunteer_hours'] = 0
    for @field in ['escort_volunteer_hours', 'admin_volunteer_hours', 'total_volunteer_hours']
      if @fields.member? field
        @fields['volunteer_hours'] += 1
      end
    end
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
  def group(groups, records)
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


  # Apply the specified block to the leaves of a nested hash (leaves
  # are defined as elements {depth} levels deep, so that hashes
  # can be leaves)
  def apply_to_leaves!(group, depth, &block) 
    if depth == 0
      return block.call group
    else
      group.each do |k, v|
        group[k] = apply_to_leaves! v, depth - 1, &block
      end
      return group
    end
  end

  def get_by_key(groups, hash, keysrc)
    for group in groups
      val = keysrc.instance_variable_get "@#{group}"
      if hash.nil? 
        return nil
      end
      hash = hash[val]
    end
    return hash
  end

end
