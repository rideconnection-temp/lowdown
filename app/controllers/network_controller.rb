require 'csv'

def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class NetworkController < ApplicationController

  before_filter :require_user
  before_filter :require_admin_user, :except=>[:csv, :predefined_report_index, :show_create_report, :report, :index]

  class NetworkReportRow
    @@attrs = [:allocation, :county, :provider_id, :funds, :fares, :agency_other, :vehicle_maint, :donations, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :undup_riders, :driver_volunteer_hours, :total_last_year, :administrative, :operations]
    attr_accessor *@@attrs

    def numeric_fields
      return [:funds, :fares, :agency_other, :vehicle_maint, :donations, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :driver_volunteer_hours, :total_last_year, :undup_riders, :administrative, :operations]
    end

    @@selector_fields = ['allocation', 'county', 'provider_id', 'project_name']
    def csv(requested_fields = nil)
      result = []

      the_fields = NetworkReportRow.fields(requested_fields)
      the_fields.each do |attr|
        result << self.send(attr).to_s
      end
      return result
    end

    def self.fields(requested_fields=nil)
      if requested_fields.nil?
        fields = @@attrs.map { |x| x.to_s } + ["cost_per_hour", "cost_per_mile", "cost_per_trip"]
      else
        fields = @@selector_fields + requested_fields.keys
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

    def agency
      return @agency
    end

    def agency=(agency)
      @agency = agency
    end

    def total
      total = 0
      cost_fields = [:funds, :fares, :agency_other, :vehicle_maint, :donations, :administrative, :operations]
      for field in cost_fields
        if @fields_to_show.nil? or @fields_to_show.member? field.to_sym
          total += instance_variable_get("@#{field}")
        end
      end
      return total
    end

    def driver_total_hours
      return driver_paid_hours + driver_volunteer_hours
    end

    def total_volunteer_hours
      return escort_volunteer_hours + admin_volunteer_hours
    end

    def total_trips
      return @in_district_trips + @out_of_district_trips
    end

    def cost_per_hour
      return total / driver_total_hours
    end

    def cost_per_trip
      return total / total_trips
    end

    def cost_per_mile
      cpm = total / @mileage
      if @mileage == 0
        return -1
      end
      return cpm
    end

    def miles_per_ride
      return @mileage / total_trips
    end

    def quarter
      q = allocation.quarter.to_s
      return q[0...4] + 'Q' + q[4]
    end

    def year
      return allocation.year.to_s
    end

    def month
      return Date.new(allocation.year, allocation.month, 1).strftime "%Y %b"
    end

    def name
      return allocation.name
    end

    def project_number
      return allocation.project_number
    end

    def funding_source
      return allocation.funding_source
    end

    def funding_subsource
      return allocation.funding_subsource
    end

    def project_name
      allocation.project.name
    end

    def include_row(row)
      @funds += row.funds
      @fares += row.fares

      @total_last_year += row.total_last_year

      @in_district_trips += row.in_district_trips
      @out_of_district_trips += row.out_of_district_trips

      @mileage += row.mileage

      @driver_paid_hours += row.driver_paid_hours

      @turn_downs += row.turn_downs
      @undup_riders += row.undup_riders

      @escort_volunteer_hours += row.escort_volunteer_hours

      @vehicle_maint += row.vehicle_maint

      @administrative += row.administrative
      @operations += row.operations

    end

    def apply_results(add_result, subtract_result={})
      for field in add_result.keys
        var = "@#{field}"
        old = instance_variable_get var
        new = old + add_result[field].to_i - subtract_result[field].to_i
        instance_variable_set var, new
      end
    end

    def collect_adjustment_by_summary(sql, allocation, start_date, end_date)
      subtract_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end > ? and 
summary_rows.valid_start < ? and summary_rows.valid_end > ? and summary_rows.valid_end <= ? "

      subtract_results = ActiveRecord::Base.connection.select_all(bind([subtract_sql, allocation['id'], 
start_date, start_date, 
start_date, start_date, end_date]))

      add_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end > ? and 
summary_rows.valid_start < ? and summary_rows.valid_end > ? and summary_rows.valid_end <= ? "

      add_results = ActiveRecord::Base.connection.select_all(bind([add_sql, allocation['id'], 
end_date, end_date, 
start_date, end_date, end_date]))

      return add_results, subtract_results
    end

    def collect_adjustment_by_trip(sql, allocation, start_date, end_date)

      #in adjustment mode, we add data from trips that are valid at
      #end_date, and subtract data form trips that are valid at
      #start_date.  We ignore trips that are valid at both or neither.

      subtract_sql = sql + "and runs.valid_start <= ? and runs.valid_end >= ?
and trips.valid_start <= ? and trips.valid_end > ? and trips.valid_end <= ? "

      subtract_results = ActiveRecord::Base.connection.select_all(bind([subtract_sql, allocation['id'], 
start_date, start_date, 
start_date, start_date, end_date ]))

      add_sql = sql + "and runs.valid_start <= ? and runs.valid_end >= ?
and trips.valid_start > ? and trips.valid_start <= ? and trips.valid_end > ? "

      add_results = ActiveRecord::Base.connection.select_all(bind([add_sql, allocation['id'], 
end_date, end_date, 
start_date, end_date, end_date ]))
      return add_results, subtract_results
    end

    def collect_trips_by_trip(allocation, start_date, end_date, pending=false, adjustment=false)
      pending_where = pending ? "runs.complete=true and " : ""

      sql = "select 
sum(case when in_trimet_district=true then 1 + guest_count + attendant_count else 0 end) as in_district_trips,
sum(case when in_trimet_district=false then 1 + guest_count + attendant_count else 0 end) as out_of_district_trips,
sum(case when result_code='TD' then 1 else 0 end) as turn_downs,
count(distinct customer_id) as undup_riders
from trips
inner join runs on trips.run_id=runs.base_id 
where
#{pending_where}
trips.allocation_id = ?
"

      if adjustment
        add_results, subtract_results = collect_adjustment_by_trip(sql, allocation, start_date, end_date)
      else
        sql += "and runs.valid_end=?
and trips.valid_end = ?
and trips.date between ? and ? "

        add_results = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], Run.end_of_time, Trip.end_of_time, start_date, end_date]))
        subtract_results = [{}]
      end

      apply_results(add_results[0], subtract_results[0])
    end

    #For a summary, there are actually two sets of fields that are
    #relevant: period_start/period_end and valid_start/valid_end.  In
    #the attribute-to-for case, we look at the period dates; in the
    #attribute-to-made case, we look at the valid dates (minus one
    #month)
    def collect_trips_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      pending_where = pending ? "summaries.complete=true and " : ""

      sql = "select 
sum(in_district_trips) as in_district_trips,
sum(out_of_district_trips) as out_of_district_trips,
sum(turn_downs) as turn_downs,
sum(unduplicated_riders) as undup_riders
from summaries 
inner join summary_rows on summary_rows.summary_id = summaries.base_id
where 
#{pending_where}
allocation_id=? "

      if adjustment
        add_results, subtract_results = collect_adjustment_by_summary(sql, allocation, start_date, end_date)

      else
        sql += "and period_start >= ? and period_end < ? and 
summaries.valid_end = ? and 
summary_rows.valid_end = ? "

        add_results = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Summary.end_of_time, SummaryRow.end_of_time]))
        subtract_results = [{}]
      end
      apply_results(add_results[0], subtract_results[0])
    end

    def collect_runs_by_trip(allocation, start_date, end_date, pending=false, adjustment=false)
      pending_where = pending ? "runs.complete=true and " : ""
      sql = "
select 
sum(apportioned_mileage) as mileage, 
sum(case when volunteer_trip=false then apportioned_duration else 0 end) as driver_paid_hours,
sum(case when volunteer_trip=true  then apportioned_duration else 0 end) as driver_volunteer_hours,
sum(runs.escort_count * apportioned_duration) as escort_volunteer_hours,
0 as admin_volunteer_hours
from trips
inner join runs on trips.run_id = runs.base_id
where
#{pending_where}
allocation_id = ? "


      if adjustment
        add_results, subtract_results = collect_adjustment_by_trip(sql, allocation, start_date, end_date)
      else
        sql += "and trips.date between ? and ?
and trips.valid_end = ? and runs.valid_end=? "

        add_results = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Trip.end_of_time, Run.end_of_time]))
        subtract_results = [{}]
      end

      apply_results(add_results[0], subtract_results[0])

    end

    def collect_runs_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      pending_where = pending ? "summaries.complete=true and " : ""
      sql = "select
sum(total_miles) as mileage,
sum(driver_hours_paid) as driver_paid_hours,
sum(driver_hours_volunteer) as driver_volunteer_hours,
sum(escort_hours_volunteer) as escort_volunteer_hours
from summaries inner join summary_rows on summary_rows.summary_id=summaries.base_id
where 
#{pending_where}
allocation_id=? "

      if adjustment
        add_results, subtract_results = collect_adjustment_by_summary(sql, allocation, start_date, end_date)
      else
        sql += "and period_start >= ? and period_end < ? and 
summaries.valid_end = ? and 
summary_rows.valid_end = ? "

        add_results = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Summary.end_of_time, SummaryRow.end_of_time]))
        subtract_results = [{}]
      end
      apply_results(add_results[0], subtract_results[0])
    end

    def collect_costs_by_trip(allocation, start_date, end_date, pending=false, adjustment=false)
      pending_where = pending ? "runs.complete=true and " : ""
      sql = "
select 
sum(fare) as funds, 
sum(customer_pay) as fares, 
0 as agency_other,
0 as donations
from trips
inner join runs on trips.run_id = runs.base_id
where
#{pending_where}
trips.allocation_id = ? "

      last_year_sql =  "select
sum(fare) + sum(customer_pay) as total_last_year
from trips
inner join runs on runs.base_id = trips.run_id
where
#{pending_where}
trips.allocation_id = ? "

      if adjustment
        add_results, subtract_results = collect_adjustment_by_trip(sql, allocation, start_date, end_date)
        apply_results(add_results[0], subtract_results[0])
        add_results, subtract_results = collect_adjustment_by_trip(last_year_sql, allocation, start_date.prev_year, end_date.prev_year)
        apply_results(add_results[0], subtract_results[0])
      else
        period_sql = "and trips.date >= ? and 
trips.date < ? and 
runs.valid_end = ? "
        sql += period_sql
        last_year_sql += period_sql
        add_results = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Run.end_of_time]))
        apply_results(add_results[0])
        add_results = ActiveRecord::Base.connection.select_all(bind([last_year_sql, allocation['id'], start_date.prev_year, end_date.prev_year, Run.end_of_time]))
        apply_results(add_results[0])
      end
    end

    def collect_costs_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      pending_where = pending ? "summaries.complete=true and " : ""
      sql = "select
sum(funds) as funds,
sum(agency_other) as agency_other,
sum(donations) as donations
from summaries 
inner join summary_rows on summary_rows.summary_id = summaries.base_id
where 
#{pending_where}
allocation_id=?  
"
      last_year_sql = "select
sum(donations + funds + agency_other) as total_last_year
from summaries 
inner join summary_rows on summary_rows.summary_id = summaries.base_id
where
#{pending_where}
allocation_id=? "

      if adjustment
        add_results, subtract_results = collect_adjustment_by_summary(sql, allocation, start_date, end_date)
        apply_results(add_results[0], subtract_results[0])
        add_results, subtract_results = collect_adjustment_by_summary(last_year_sql, allocation, start_date.prev_year, end_date.prev_year)
        apply_results(add_results[0], subtract_results[0])
      else
        period_sql = "and summaries.period_start >= ? and 
summaries.period_end < ? and 
summaries.valid_end = ? and summary_rows.valid_end = ? "
        sql += period_sql
        last_year_sql += period_sql
        add_results = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Summary.end_of_time, SummaryRow.end_of_time]))
        apply_results(add_results[0])

        add_results = ActiveRecord::Base.connection.select_all(bind([last_year_sql, allocation['id'], start_date.prev_year, end_date.prev_year, Summary.end_of_time, SummaryRow.end_of_time]))
        apply_results(add_results[0])
      end
    end

    def collect_operation_data_by_summary(allocation, start_date, end_date, pending=false, adjustment=false)
      pending_where = pending ? "summaries.complete=true and " : ""
      sql = "select
sum(operations) as operations,
sum(administrative) as administrative,
sum(vehicle_maint) as vehicle_maint
from summaries 
where 
#{pending_where}
allocation_id=?  
"
      if adjustment
        subtract_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end >= ? "

        subtract_results = ActiveRecord::Base.connection.select_all(bind([subtract_sql, allocation['id'], 
start_date, start_date]))

        add_sql = sql + "and summaries.valid_start <= ? and summaries.valid_end >= ? "

        add_results = ActiveRecord::Base.connection.select_all(bind([add_sql, allocation['id'], 
end_date, end_date ]))

        apply_results(add_results[0], subtract_results[0])
      else
        period_sql = "and summaries.period_start >= ? and 
summaries.period_end < ? and 
summaries.valid_end = ? "
        sql += period_sql
        add_results = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Summary.end_of_time]))
        apply_results(add_results[0])
      end
    end

  end


  @@group_mappings = {
    "agency" => "providers.agency",
    "county" => "allocations.county",
    "name" => "allocations.name",
    "funding_source" => "projects.funding_source",
    "funding_subsource" => "projects.funding_subsource",
    "project_name" => "projects.name",
    "project_number" => "projects.project_number",
    "quarter" => "quarter",
    "month" => "month"
  }

  @@time_periods = [
    "year", "quarter", "month"
  ]

  def index

    #network service summary

    groups = "allocations.county,providers.agency"
    group_fields = ['county', 'agency']

    #past two weeks
    end_date = Date.today
    start_date = end_date - 14 
    do_report(groups, group_fields, start_date, end_date, nil, nil, false, false)
    @params = {:q=>{}}
    render 'report'
  end

  def report_index
    @reports = Report.all
  end

  def show_create_report
    @report = Report.new(params[:q])
    @allocations = Allocation.all
  end

  def show_create_quarterly
    @report = Report.new(params[:q])
  end

  def csv
    report = Report.new(params[:q])
    group_fields = report.group_by

    if group_fields.nil?
      show_create_report
      return render 'show_create_report'
    end

    group_fields = group_fields.split(",")

    groups = group_fields.map { |f| @@group_mappings[f] }

    do_report(groups, group_fields, report.start_date, report.end_date, report.allocations, report.fields, report.pending, report.adjustment)
    csv_string = CSV.generate do |csv|
      csv << NetworkReportRow.fields(report.fields)
      apply_to_leaves! @results, group_fields.size,  do | row |
        csv << row.csv(report.fields)
        nil
      end
    end


    return render :text=> csv_string, :content_type=>"text/plain"
  end

  def sum(rows, out=nil)
    if out.nil?
      out = NetworkReportRow.new
    end
    if rows.instance_of? Hash
      rows.each do |key, row|
        sum(row, out)
      end
    else
      out.include_row(rows)
    end
    return out
  end

  def report
    if params[:report] and params[:report][:id]
      report = Report.find(params[:report][:id])
      report.update_attributes params[:report]
    else
      report = Report.new(params[:q])
      report.fields = params[:q][:fields]
      report.allocations = params[:q][:allocations]
    end
    @params = params
    group_fields = report.group_by

    if group_fields.nil?
      show_create_report
      return render 'show_create_report'
    end

    group_fields = group_fields.split(",")

    groups = group_fields.map { |f| @@group_mappings[f] }

    do_report(groups, group_fields, report.start_date, report.end_date, report.allocations, report.fields, report.pending, report.adjustment)
    @report = report
  end

  def save_report
    if params[:report][:id].empty?
      report = Report.new(params[:report])
    else
      report = Report.find(params[:report][:id])
      report.update_attributes(params[:report])
    end
    report.save!
    flash[:notice] = "Saved #{report.name}"
    redirect_to :action=>:report, :id=>report.id
  end

  def quarterly_narrative_report
    @report = Report.new(params[:q])
    @report.end_date = @report.start_date.next_month.next_month.next_month

    groups = "allocations.name,month"
    group_fields = ['name', 'month']

    do_report(groups, group_fields, @report.start_date, @report.end_date, nil, nil, false, false)

    @quarter = @report.start_date.month / 3 + 1
    @allocations = @results
  end

  private 

  def add_months(date, months)
    year = date.year
    month = date.month + months
    while month > 12
      month -= 12
      year += 1
    end
    Date.new(year, month, date.day)
  end

  class PeriodAllocation
    attr_accessor :quarter, :year, :month, :period_start_date, :period_end_date

    def initialize(allocation, period_start_date, period_end_date)
      @allocation = allocation
      @period_start_date = period_start_date
      @period_end_date = period_end_date
      @quarter = period_start_date.year * 10 + period_start_date.month / 3 + 1
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

    period_end_date = add_months period_start_date, advance

    periods = []
    begin
      periods += allocations.map do |allocation|
        PeriodAllocation.new allocation, period_start_date, period_end_date
      end

      period_start_date = add_months period_start_date, advance
      period_end_date = add_months period_end_date, advance
    end while period_end_date <= end_date

    periods
  end


  # Collect all data, and summarize it grouped according to the groups provided.
  # groups: the names of groupings, in order from coarsest to finest (i.e. project_name, quarter)
  # group_fields: the names of groupings with table names (i.e. projects.name, quarter)
  # allocation: an list of allocations to restrict the report to
  # fields: a list of fields to display

  def do_report(groups, group_fields, start_date, end_date, allocations, fields, pending, adjustment)
    group_select = []

    for group,field in groups.split(",").zip group_fields
      group_select << "#{group} as #{field}"
    end

    group_select = group_select.join(",")

    if allocations.nil? or allocations.size == 0
      results = Allocation.all
    else
      results = Allocation.where(["id in ?", allocations]).all
    end

    for period in @@time_periods
      if group_fields.member? period
        results = apply_periods(results, start_date, end_date, period)
      end
    end

    allocations = group(group_fields, results)

    apply_to_leaves! allocations, group_fields.size, do | allocationset |

      row = NetworkReportRow.new fields

      for allocation in allocationset
        row.agency = allocation.agency
        if allocation.respond_to? :period_start_date 
          #this is not working for some reason?
          start_date = allocation.period_start_date
          end_date = allocation.period_end_date
        end
        if allocation['trip_collection_method'] == 'trips'
          row.collect_trips_by_trip(allocation, start_date, end_date, pending, adjustment)
        else
          row.collect_trips_by_summary(allocation, start_date, end_date, pending, adjustment)
        end

        if allocation['run_collection_method'] == 'trips' or allocation['run_collection_method'] == 'runs'
          row.collect_runs_by_trip(allocation, start_date, end_date, pending, adjustment)
        else
          row.collect_runs_by_summary(allocation, start_date, end_date, pending, adjustment)
        end

        if allocation['cost_collection_method'] == 'trips' or allocation['cost_collection_method'] == 'runs'
          row.collect_costs_by_trip(allocation, start_date, end_date, pending, adjustment)
        else
          row.collect_costs_by_summary(allocation, start_date, end_date, pending, adjustment)
        end

        row.collect_operation_data_by_summary(allocation, start_date, end_date, pending, adjustment)

      end
      row.allocation = allocationset[0]
      row.county = allocationset[0].county
      row.provider_id = allocationset[0].provider_id
      row
    end

    @levels = group_fields.size
    @group_fields = group_fields
    @results = allocations
    @start_date = start_date
    @end_date = end_date
    @tr_open = false
    @fields = {}
    if fields.nil? or fields.empty?
      NetworkReportRow.fields.each do |field| 
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
