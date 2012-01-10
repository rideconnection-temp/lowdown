require 'csv'

def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class ReportsController < ApplicationController

  before_filter :require_admin_user, :except=>[:csv, :new, :create, :age_and_ethnicity, :show_create_age_and_ethnicity, :report, :index, :quarterly_narrative_report, :show_create_quarterly, :show_create_active_rider]

  class ReportRow
    @@attrs = [:allocation, :funds, :agency_other, :vehicle_maint, :donations, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :undup_riders, :driver_volunteer_hours, :total_last_year, :administrative, :operations]
    attr_accessor *@@attrs

    def numeric_fields
      return [:funds, :agency_other, :vehicle_maint, :donations, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :driver_volunteer_hours, :total_last_year, :undup_riders, :administrative, :operations]
    end

    @@selector_fields = ['allocation', 'county', 'provider_id', 'project_name']
    def csv(requested_fields = nil)
      result = []

      the_fields = ReportRow.fields(requested_fields)
      the_fields.each do |attr|
        result << self.send(attr).to_s
      end
      return result
    end

    def self.fields(requested_fields=nil)
      if requested_fields.nil? || requested_fields.empty?
        fields = @@attrs.map { |x| x.to_s } + ["cost_per_hour", "cost_per_mile", "cost_per_trip", "miles_per_ride"]
      else
        fields = @@selector_fields + requested_fields
      end
      fields.delete 'driver_hours'
      fields.delete 'volunteer_hours'

      fields.sort!

    end

    def initialize(fields_to_show = nil)

      for k in numeric_fields
        self.instance_variable_set("@#{k}", 0.0)
      end

      @fields_to_show = fields_to_show

    end

    def total
      total = 0
      cost_fields = [:funds, :agency_other, :vehicle_maint, :donations, :administrative, :operations]
      for field in cost_fields
        if @fields_to_show.nil? || @fields_to_show.map(&:to_sym).member?( field.to_sym )
          total += instance_variable_get("@#{field}")
        end
      end
      total
    end

    def driver_total_hours
      driver_paid_hours + driver_volunteer_hours
    end

    def total_volunteer_hours
      escort_volunteer_hours + admin_volunteer_hours
    end

    def total_trips
      @in_district_trips + @out_of_district_trips
    end

    def cost_per_hour
      if driver_total_hours == 0
        nil
      else
        total / driver_total_hours
      end
    end

    def cost_per_trip
      if total_trips == 0
        nil
      else
        total / total_trips
      end
    end

    def cost_per_mile
      if @mileage == 0
        nil
      else
        total / @mileage
      end
    end

    def miles_per_ride
      if total_trips == 0
        nil
      else
        @mileage / total_trips
      end
    end

    def quarter
      q = allocation.quarter.to_s
      #adjust for fiscal year
      year = q[0...4].to_i
      qtr = q[4].to_i
      if qtr >= 3
        qtr -= 2
        year += 1
      else
        qtr += 2
      end

      'FY %s-%s Q%s' % [year-1, year.to_s[-2,2], qtr]
    end

    def year
      allocation.year.to_s
    end

    def month
      Date.new(allocation.year, allocation.month, 1).strftime "%Y %b"
    end

    def allocation_name
      allocation.name
    end

    def project_number
      allocation.project_number
    end

    def program
      allocation.program
    end

    def funding_source
      allocation.funding_source
    end

    def funding_subsource
      allocation.funding_subsource
    end

    def project_name
      allocation.project.try :name
    end

    def agency
      allocation.provider.try :agency
    end

    def county
      allocation.county
    end
    
    def short_county
      allocation.short_county
    end
    
    def provider_id
      allocation.provider_id
    end

    def provider_name
      allocation.provider.try :name
    end

    def short_provider_name
      allocation.provider.try :short_name
    end

    def include_row(row)
      @funds                  += row.funds
      @agency_other           += row.agency_other
      @vehicle_maint          += row.vehicle_maint
      @administrative         += row.administrative
      @operations             += row.operations
      @donations              += row.donations
      
      @in_district_trips      += row.in_district_trips
      @out_of_district_trips  += row.out_of_district_trips
      @total_last_year        += row.total_last_year
      @mileage                += row.mileage

      @driver_volunteer_hours += row.driver_volunteer_hours
      @driver_paid_hours      += row.driver_paid_hours

      @turn_downs             += row.turn_downs
      @undup_riders           += row.undup_riders
      @escort_volunteer_hours += row.escort_volunteer_hours
      @admin_volunteer_hours  += row.admin_volunteer_hours
    end

    def apply_results(add_result, subtract_result={})
      for field in add_result.keys
        var = "@#{field}"
        old = instance_variable_get var
        new = old + add_result[field].to_i - subtract_result[field].to_i
        instance_variable_set var, new
      end if add_result.present?
    end

    def collect_adjustment_by_summary(sql, allocation, start_date, end_date)
      subtract_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end > ? "

      subtract_results = ActiveRecord::Base.connection.select_one(bind([subtract_sql, allocation['id'], 
start_date, start_date]))

      add_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end > ? "

      add_results = ActiveRecord::Base.connection.select_one(bind([add_sql, allocation['id'], 
end_date, end_date]))

      return add_results, subtract_results
    end

    def collect_adjustment_by_trip(sql, allocation, start_date, end_date)

      #in adjustment mode, we add data from trips that are valid at
      #end_date, and subtract data form trips that are valid at
      #start_date.  We ignore trips that are valid at both or neither.

      subtract_sql = sql + "and runs.valid_start <= ? and runs.valid_end >= ?
and trips.valid_start <= ? and trips.valid_end > ? and trips.valid_end <= ? "

      subtract_results = ActiveRecord::Base.connection.select_one(bind([subtract_sql, allocation['id'], 
start_date, start_date, 
start_date, start_date, end_date ]))

      add_sql = sql + "and runs.valid_start <= ? and runs.valid_end >= ?
and trips.valid_start > ? and trips.valid_start <= ? and trips.valid_end > ? "

      add_results = ActiveRecord::Base.connection.select_one(bind([add_sql, allocation['id'], 
end_date, end_date, 
start_date, end_date, end_date ]))
      return add_results, subtract_results
    end

    def collect_trips_by_trip(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Trip.select("sum(case when in_trimet_district=true and result_code = 'COMP' then 1 + guest_count + attendant_count else 0 end) as in_district_trips, sum(case when in_trimet_district=false and result_code = 'COMP' then 1 + guest_count + attendant_count else 0 end) as out_of_district_trips, sum(case when result_code='TD' then 1 + guest_count + attendant_count else 0 end) as turn_downs")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        add_results, subtract_results = collect_adjustment_by_trip(sql, allocation, start_date, end_date)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)

        pending_where = pending ? "" : "complete=true and " 
        undup_riders_sql = "select count(*) as undup_riders from (select customer_id, fiscal_year(date) as year, min(fiscal_month(date)) as month from trips where #{pending_where}allocation_id=? and valid_end=? and result_code = 'COMP' group by customer_id, year) as morx where date (year || '-' || month || '-' || 1)  between ? and ? "
        row = ActiveRecord::Base.connection.select_one(bind([undup_riders_sql, allocation['id'], Trip.end_of_time, start_date.advance(:months=>6), end_date.advance(:months=>6)]))
        add_results['undup_riders'] = row['undup_riders'].to_i

        subtract_results = {}
      end

      apply_results(add_results, subtract_results)
    end

    def collect_trips_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Summary.select("sum(in_district_trips) as in_district_trips, sum(out_of_district_trips) as out_of_district_trips, turn_downs, unduplicated_riders as undup_riders")
      results = results.where(:allocation_id => allocation['id'])
      results = results.joins(:summary_rows).group("turn_downs, summaries.unduplicated_riders")
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        add_results, subtract_results = collect_adjustment_by_summary(sql + group_by, allocation, start_date, end_date)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
        subtract_results = {}
      end
      apply_results(add_results, subtract_results)
    end

    def collect_runs_by_trip(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/60.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/60.0 as driver_volunteer_hours, 0 as escort_volunteer_hours, 0 as admin_volunteer_hours")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        add_results, subtract_results = collect_adjustment_by_trip(sql, allocation, start_date, end_date)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
        subtract_results = {}
      end
      apply_results(add_results, subtract_results)
    end

    def collect_runs_by_run(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/60.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/60.0 as driver_volunteer_hours, sum(COALESCE((SELECT escort_count FROM runs where id = trips.run_id),0) * apportioned_duration)/60.0 as escort_volunteer_hours, 0 as admin_volunteer_hours")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        add_results, subtract_results = collect_adjustment_by_trip(sql, allocation, start_date, end_date)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
        subtract_results = {}
      end
      apply_results(add_results, subtract_results)
    end

    def collect_runs_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Summary.select("sum(total_miles) as mileage, sum(driver_hours_paid) as driver_paid_hours, sum(driver_hours_volunteer) as driver_volunteer_hours, sum(administrative_hours_volunteer) as admin_volunteer_hours, sum(escort_hours_volunteer) as escort_volunteer_hours")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        add_results, subtract_results = collect_adjustment_by_summary(sql + group_by, allocation, start_date, end_date)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
        subtract_results = {}
      end
      apply_results(add_results, subtract_results)
    end

    def collect_costs_by_trip(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Trip.select("sum(fare) as funds, 0 as agency_other, 0 as donations")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        add_results, subtract_results = collect_adjustment_by_trip(sql, allocation, start_date, end_date)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
        subtract_results = {}
      end
      apply_results(add_results)
    end

    def collect_costs_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Summary.select("sum(funds) as funds, sum(agency_other) as agency_other, sum(donations) as donations")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        add_results, subtract_results = collect_adjustment_by_summary(sql + group_by, allocation, start_date, end_date)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
        subtract_results = {}
      end
      apply_results(add_results, subtract_results)
    end

    def collect_operation_data_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      results = Summary.select("sum(operations) as operations, sum(administrative) as administrative, sum(vehicle_maint) as vehicle_maint")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless pending

      if adjustment && false # turn off adjustments option for now
        subtract_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end >= ? "
        subtract_results = ActiveRecord::Base.connection.select_one(bind([subtract_sql, allocation['id'], start_date, start_date]))
        add_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end >= ? "
        add_results = ActiveRecord::Base.connection.select_one(bind([add_sql, allocation['id'], end_date, end_date ]))
        apply_results(add_results, subtract_results)
      else
        add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
        subtract_results = {}
      end
      apply_results(add_results, subtract_results)
    end

  end

  @@time_periods = [
    "year", "quarter", "month"
  ]

  def index
    @reports = Report.all
  end

  def new
    @report      = Report.new(params[:report])
    prep_edit
  end

  def create
    @report = Report.new_from_params params

    if @report.save
      flash[:notice] = "Saved #{@report.name}"
      redirect_to edit_report_path(@report)
    else
      prep_edit
      render :action => :new
    end
  end

  # the results of the report
  def show
    @report       = Report.find params[:id]
    @group_fields = @report.group_by.split(",")
    groups        = @group_fields.map { |f| Report::GroupMappings[f] }
    @groups_size  = groups.size
    filters       = {}
    filters[:funding_subsource_names] = @report.funding_subsource_names if @report.funding_subsource_name_list.present?
    filters[:provider_ids]            = @report.provider_ids            if @report.provider_list.present?
    filters[:program_names]           = @report.program_names           if @report.program_name_list.present?
    filters[:county_names]            = @report.county_names            if @report.county_name_list.present?

    do_report(groups, @group_fields, @report.start_date, @report.query_end_date, @report.allocations, @report.fields, @report.pending, @report.adjustment, @report.adjustment_start_date, @report.query_adjustment_end_date,filters)
  end

  def csv
    show

    csv_string = CSV.generate do |csv|
      csv << ReportRow.fields(@report.fields)
      apply_to_leaves! @results, @group_fields.size,  do | row |
        csv << row.csv(@report.fields)
        nil
      end
    end

    send_data csv_string, :type => "text/plain", :filename => "report.csv", :disposition => 'attachment'
  end

  def edit
    @report      = Report.find params[:id]
    prep_edit
  end

  def update
    @report      = Report.find params[:id]

    if @report.update_attributes params[:report]
      if params[:commit].downcase.match /view/
        redirect_to report_path(@report)
      else
        flash[:notice] = "Saved #{@report.name}"
        redirect_to edit_report_path(@report.id)
      end
    else
      prep_edit
      render :action => :edit
    end
  end

  def destroy
    report = Report.destroy params[:id]
    flash[:notice] = "Deleted #{report.name}"
    redirect_to :action => :index
  end
  
  def sort
    params[:reports].each do |id, index|
      Report.update_all(['position=?', index], ['id=?', id])
    end
    render :nothing => true
  end

  def show_create_quarterly
    if params[:report].blank? || params[:report][:start_date].blank? || params[:report][:end_date].blank?
      quarter_start = Date.new(Date.today.year, (Date.today.month-1)/3*3+1,1)
      params[:report] = {}
      params[:report][:start_date] = quarter_start - 3.months
      params[:report][:end_date] = quarter_start - 1.months
    end
    @report = Report.new(params[:report])
  end
  
  def show_create_active_rider
    @start_date = start_month_from_params params[:active_rider_query]
    @after_end_date = @start_date.next_month
        
    trips = Trip.current_versions.completed.spd.date_range(@start_date,@after_end_date).includes(:customer)

    @spd_offices = {}
    @customer_rows = {}
    @approved_rides = 0
    @wc_billed_rides = @nonwc_billed_rides = @unknown_billed_rides = 0
    @wc_mileage = @nonwc_mileage = @unknown_mileage = 0

    for trip in trips
      row_key = [trip.customer_id, trip.wheelchair?]
      customer = trip.customer
      office_key = trip.spd_office
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

  def sum(rows, out=nil)
    out ||= ReportRow.new

    if rows.instance_of? Hash
      rows.each do |key, row|
        sum(row, out)
      end
    else
      out.include_row(rows)
    end
    
    return out
  end


  class RidePurposeRow

    @@trip_purposes = POSSIBLE_TRIP_PURPOSES + ["Unspecified", "Total"]

    attr_accessor :county, :provider, :by_purpose

    def initialize
      @by_purpose = {}
      for purpose in @@trip_purposes
        @by_purpose[purpose] = 0
      end
    end

    def collect_by_trip(allocation, start_date, end_date)
      sql = "select
purpose_type as purpose, count(*) as trips from trips where result_code='COMP' 
and allocation_id=? and date between ? and ? and valid_end = ?
group by purpose_type; "

      rows = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Trip.end_of_time]))

      total = 0
      for row in rows
        total += row['trips'].to_i
        @by_purpose[TRIP_PURPOSE_TO_SUMMARY_PURPOSE[row['purpose']]] += row['trips'].to_i
      end
      @by_purpose["Total"] = total
    end

    def collect_by_summary(allocation, start_date, end_date)
      sql = "select
purpose, in_district_trips + out_of_district_trips as trips from
summary_rows, summaries
where summary_rows.summary_id = summaries.base_id and 
allocation_id=? and period_start >= ? and period_end <= ? and summaries.valid_end = ?
"

      rows = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Summary.end_of_time]))

      total = 0
      for row in rows
        total += row['trips'].to_i
        @by_purpose[row['purpose']] += row['trips'].to_i
      end
      @by_purpose["Total"] = total
    end

    def include_row(row)
      for purpose in @@trip_purposes
        @by_purpose[purpose] += row.by_purpose[purpose]
      end
    end

    def percentages
      grand_total = @by_purpose["Total"]
      percentages = {}
      for purpose in @@trip_purposes
        percentages[purpose] = @by_purpose[purpose] * 100.0 / grand_total
      end
      percentages
    end

    def self.trip_purposes
      return @@trip_purposes
    end
  end

  def sum_ride_purposes(rows, out=nil)
    if out.nil?
      out = RidePurposeRow.new
    end
    if rows.instance_of? Hash
      rows.each do |key, row|
        sum_ride_purposes(row, out)
      end
    else
      out.include_row(rows)
    end
    return out
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
    @report = Report.new(params[:report])
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
    @providers = Provider.all
    @agencies = @providers.map { |x| "%s:%s" % [x.agency, x.branch] }
  end

  def age_and_ethnicity
    @start_date = Date.new(params[:q]["start_date(1i)"].to_i, params[:q]["start_date(2i)"].to_i, 1)

    @agency, @branch = params[:q][:agency_branch].split(":")

    allocations = Allocation.joins(:provider).where(["agency = ? and branch = ? and exists(select id from trips where trips.allocation_id=allocations.id)", @agency, @branch])

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

    #same, but w/disability
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_age_sql % "and month = ? and disabled=true",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @start_date.advance(:months=>6).year, 
                                                          @start_date.advance(:months=>6).month]))


    @disability_disclosed_old = @disability_disclosed_young = @disability_disclosed_unknown = 0
    for row in rows
      if row['over60'] == 't'
        @disability_disclosed_old = row['undup_riders'].to_i
      elsif row['over60'] == 'f'
        @disability_disclosed_young = row['undup_riders'].to_i
      else
        @disability_disclosed_unknown = row['undup_riders'].to_i
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
      @ethnicity[row["race"]] = {"unduplicated" => row["unduplicated"]}
    end

    #ethnicity ytd
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_ethnicity_sql % "",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @start_date.advance(:months=>6).year]))

    for row in rows
      race = row["race"]
      if ! @ethnicity.member? race
        @ethnicity[race] = {"unduplicated" => 0}
      end
      @ethnicity[race]["ytd"] = row["unduplicated"]
    end

  end

  def show_create_spd_report

  end

  def spd_report
    @start_date = Date.parse(params[:date] || '2010-12-1')
    @end_date = @start_date.next_month

    trips = Trip.current_records.completed.spd.date_range(@start_date,@end_date).include(:customer)

    @spd_offices = {}
    @customer_rows = {}
    @approved_rides = 0
    @wc_billed_rides = @nonwc_billed_rides = @unknown_billed_rides = 0
    @wc_mileage = @nonwc_mileage = @unknown_mileage = 0

    for trip in trips
      if trip.mobility == "Ambulatory"
        wheelchair = false
      elsif trip.mobility == "Unknown"
        wheelchair = "unknown"
      else
        wheelchair = true
      end

      row_key = [trip.customer_id, wheelchair]
      customer = trip.customer
      office_key = customer.spd_office
      @customer_rows[office_key] = {} unless @customer_rows.has_key?(office_key)

      row = @customer_rows[office_key][row_key]
      if row.nil?
        row = {:customer => customer,
               :billed_rides=>0, :billable_mileage=>0, :mobility=>wheelchair}
        @customer_rows[office_key][row_key] = row
      end

      row[:billed_rides] += 1
      row[:billable_mileage] += trip.spd_mileage

      @approved_rides += customer.approved_rides.to_i
      if wheelchair == "unknown"
        @unknown_billed_rides += 1
        @unknown_mileage += trip.spd_mileage
      elsif wheelchair
        @wc_billed_rides += 1
        @wc_mileage += trip.spd_mileage
      else
        @nonwc_billed_rides += 1
        @nonwc_mileage += trip.spd_mileage
      end
    end
  end

  private

  def prep_edit
    @funding_subsource_names = [['<Select All>','']] + Project.funding_subsource_names
    @providers = [['<Select All>','']] + Provider.all.map {|x| [x.name, x.id]}
    @program_names = [['<Select All>','']] + Allocation.program_names
    @county_names = [['<Select All>','']] + Allocation.county_names
    @group_bys = Report::GroupBys.sort
    if @report.group_by.present?
      @group_bys = @group_bys << @report.group_by unless @group_bys.include? @report.group_by
    end
  end

  class PeriodAllocation
    attr_accessor :quarter, :year, :month, :period_start_date, :period_end_date

    def initialize(allocation, period_start_date, period_end_date)
      @allocation = allocation
      @period_start_date = period_start_date
      @period_end_date = period_end_date
      @quarter = period_start_date.year * 10 + (period_start_date.month - 1) / 3 + 1
      @year = period_start_date.year
      @month = period_start_date.month
    end

    def method_missing(method_name, *args, &block)
      @allocation.send method_name, *args, &block
    end

    def respond_to?(method)
      if instance_variables.member? "@#{method.to_s}".to_sym
        return true
      end
      return @allocation.respond_to? method
    end

    def to_s
      if period_end_date-period_start_date < 32
        return period_start_date.strftime "%Y %b"
      elsif period_end_date-period_start_date < 320
        fiscal_period_start_date = period_start_date.advance(:months=>6)
        return '%sQ%s' % [fiscal_period_start_date.year, (fiscal_period_start_date.month / 3 + 1)]
      else
        return period_start.year.to_s
      end
    end
  end

  def start_month_from_params(date_params)
    date_params.present? ? 
      Date.new( date_params["start_date(1i)"].to_i, date_params["start_date(2i)"].to_i, 1 ) : 
      Date.today.at_beginning_of_month - 1.month
  end
  
  def apply_periods(allocations, start_date, end_date, period)
    #enumerate periods between start_date and end_date
    year = start_date.year
    if period == 'year'
      period_start_date = Date.new(year, 1, 1)
      advance = 12
    elsif period == 'quarter'
      zero_based_month = start_date.month - 1
      quarter_start = (zero_based_month / 3) * 3 + 1
      period_start_date = Date.new(year, quarter_start, 1)

      advance = 3
    elsif period == 'month'
      period_start_date = Date.new(year, start_date.month, 1)
      advance = 1
    end

    period_end_date = period_start_date.advance(:months=>advance)

    periods = []
    begin
      periods += allocations.map do |allocation|
        PeriodAllocation.new allocation, period_start_date, period_end_date
      end

      period_start_date = period_start_date.advance(:months=>advance)
      period_end_date = period_end_date.advance(:months=>advance)
    end while period_end_date <= end_date

    periods
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
        results = apply_periods(results, start_date, end_date, period)
      end
    end

    allocations = group(group_fields, results)
    

    apply_to_leaves! allocations, group_fields.size do | allocationset |
      row = ReportRow.new fields

      for allocation in allocationset
        #debugger
        if allocation.respond_to? :period_start_date 
          #this is not working for some reason?
          collection_start_date = allocation.period_start_date
          collection_end_date = allocation.period_end_date
        end
        collection_start_date = adjustment ? adjustment_start_date : start_date
        collection_end_date   = adjustment ? adjustment_end_date : end_date
        if allocation['trip_collection_method'] == 'trips'
          row.collect_trips_by_trip(allocation, collection_start_date, collection_end_date, pending, adjustment)
        else
          row.collect_trips_by_summary(allocation, collection_start_date, collection_end_date, pending, adjustment)
        end

        if allocation['run_collection_method'] == 'trips' 
          row.collect_runs_by_trip(allocation, collection_start_date, collection_end_date, pending, adjustment)
        elsif allocation['run_collection_method'] == 'runs'
          row.collect_runs_by_run(allocation, collection_start_date, collection_end_date, pending, adjustment)
        else
          row.collect_runs_by_summary(allocation, collection_start_date, collection_end_date, pending, adjustment)
        end

        if allocation['cost_collection_method'] == 'trips' or allocation['cost_collection_method'] == 'runs'
          row.collect_costs_by_trip(allocation, collection_start_date, collection_end_date, pending, adjustment)
        else
          row.collect_costs_by_summary(allocation, collection_start_date, collection_end_date, pending, adjustment)
        end

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
