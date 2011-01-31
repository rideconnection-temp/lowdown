require 'csv'

class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date
  attr_accessor :end_date
  attr_accessor :group_by
  attr_accessor :tag
  attr_accessor :fields

  def convert_date(obj, base)
    return Date.new(obj["#{base}(1i)"].to_i,obj["#{base}(2i)"].to_i,obj["#{base}(3i)"].to_i)
  end

  def initialize(params)
    if params
      if params["start_date(1i)"]
        @start_date = convert_date(params, :start_date)
      else
        @end_date = Date.today
        @start_date = @end_date - 14
      end
      if params["end_date(1i)"]
        @end_date = convert_date(params, :end_date)
      end
      if params[:group_by]
        @group_by = params[:group_by]
      end
      if params[:tag]
        @tag = params[:tag]
      end
      if params[:f]
        @fields = params[:f]
      end
    end
  end

  def persisted?
    false
  end

end

def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class NetworkController < ApplicationController

  before_filter :require_user
  before_filter :require_admin_user, :except=>[:csv, :tag_index, :show_create_report, :report, :index]

  class NetworkReportRow
    @@attrs = [:allocation, :county, :provider_id, :funds, :fares, :agency_other, :vehicle_maint, :donations_fares, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :undup_riders, :driver_volunteer_hours, :total_last_year]
    attr_accessor *@@attrs

    def numeric_fields
      return [:funds, :fares, :agency_other, :vehicle_maint, :donations_fares, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :driver_volunteer_hours, :total_last_year, :undup_riders]
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

    def initialize(hash = nil)

      if hash.nil?
        for k in numeric_fields
          self.instance_variable_set("@#{k}", 0.0)
        end

        return #because this is a summary row, do not set up anything further
      end

      for field in numeric_fields
        hash[field.to_s] = hash[field.to_s].to_f
      end

      hash.each do |k,v|
        instance_variable_set("@#{k}", v)
      end

      allocation = Allocation.find(@allocation_id)
      @agency = allocation.agency
    end

    def agency
      return @agency
    end

    def agency=(agency)
      @agency = agency
    end

    def total
      return @funds + @fares + @agency_other + @vehicle_maint + @donations_fares
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
      return @funds / driver_total_hours
    end

    def cost_per_trip
      return @funds / total_trips
    end

    def cost_per_mile
      cpm = @funds / @mileage
      if @mileage == 0
        return -1
      end
      return cpm
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
    end

    def quarter_sql(field)
      return "extract(year from #{field}) * 10 + extract(quarter from #{field})"
    end

    def quarter_sql_fragments(allocation, field)
      quarter_where = ""
      if allocation.respond_to? :quarter
        quarter_where = "#{quarter_sql(field)} = #{allocation.quarter} and "
      end
      return quarter_where
    end

    def collect_trips_by_trip(allocation, start_date, end_date)
      quarter_where = quarter_sql_fragments(allocation, "trips.date")

      sql = "select 
sum(case when in_trimet_district=true then 1 else 0 end) as in_district_trips,
sum(case when in_trimet_district=false then 1 else 0 end) as out_of_district_trips,
sum(case when result_code='TD' then 1 else 0 end) as turn_downs,
count(distinct customer_id) as unduplicated_riders
from trips
inner join runs on trips.run_id=runs.base_id and runs.valid_end=?
where
#{quarter_where}
runs.complete=true and 
trips.date between ? and ?
and trips.allocation_id = ?
and trips.valid_end = ?
"

      results = ActiveRecord::Base.connection.select_all(bind([sql, Run.end_of_time, start_date, end_date, allocation['id'], Trip.end_of_time]))

      result = results[0]
      @in_district_trips += result['in_district_trips'].to_i
      @out_of_district_trips += result['out_of_district_trips'].to_i
      @turn_downs += result['turn_downs'].to_i
      @undup_riders += result['unduplicated_riders'].to_i
    end

#For a summary, there are actually two sets of fields that are relevant: period_start/period_end and valid_start/valid_end.  In the attribute-to-for case, we look at the period dates; in the attribute-to-made case, we look at the valid dates (minus one month)
    def collect_trips_by_summary(allocation, start_date, end_date)
      quarter_where = quarter_sql_fragments(allocation, "summaries.period_start")
      sql = "select 
sum(case when in_district=true then trips else 0 end) as in_district_trips,
sum(case when in_district=false then trips else 0 end) as out_of_district_trips,
sum(turn_downs),
sum(unduplicated_riders) as unduplicated_riders
from summaries 
inner join summary_rows on summary_rows.summary_id = summaries.base_id
where 
#{quarter_where}
summaries.complete=true and 
period_start >= ? and period_end < ? and 
allocation_id=? and 
summaries.valid_end = ? and 
summary_rows.valid_end = ? "

      results = ActiveRecord::Base.connection.select_all(bind([sql, start_date, end_date, allocation['id'], Summary.end_of_time, SummaryRow.end_of_time]))
      result = results[0]
      @in_district_trips += result['in_district_trips'].to_i
      @out_of_district_trips += result['out_of_district_trips'].to_i
      @turn_downs += result['turn_downs'].to_i
      @undup_riders += result['unduplicated_riders'].to_i
    end

    def quarter
      q = allocation.quarter.to_s
      return q[0...4] + 'Q' + q[4]
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


    def collect_runs_by_trip(allocation, start_date, end_date)
      quarter_where = quarter_sql_fragments(allocation, "trips.date")
      sql = "
select 
sum(trips.odometer_end - trips.odometer_start) as mileage, 
sum(duration) as driver_paid_hours,
sum(case when volunteer_trip=true then duration else 0 end) as driver_volunteer_hours,
sum(runs.escort_count * duration) as escort_volunteer_hours,
0 as admin_volunteer_hours,
max(allocation_id) as allocation_id
from trips
inner join runs on trips.run_id = runs.base_id
where
#{quarter_where}
runs.complete=true and 
trips.date between ? and ?
and allocation_id = ? and trips.valid_end = ? and runs.valid_end=? "

      results = ActiveRecord::Base.connection.select_all(bind([sql, start_date, end_date, allocation['id'], Trip.end_of_time, Run.end_of_time]))

      result = results[0]
      @mileage += result['mileage'].to_f
      @driver_paid_hours += result['driver_paid_hours'].to_f
      @driver_volunteer_hours += result['driver_volunteer_hours'].to_f
      @escort_volunteer_hours += result['escort_volunteer_hours'].to_f

    end

    def collect_runs_by_summary(allocation, start_date, end_date)
      quarter_where = quarter_sql_fragments(allocation, "summaries.period_start")
      sql = "select
sum(total_miles) as mileage,
sum(driver_hours_paid) as driver_paid_hours,
sum(driver_hours_volunteer) as driver_volunteer_hours,
sum(escort_hours_volunteer) as escort_volunteer_hours
from summaries 
where 
#{quarter_where}
summaries.complete=true and 
period_start >= ? and 
period_end < ? and 
allocation_id=? and 
valid_end = ? "

      results = ActiveRecord::Base.connection.select_all(bind([sql, start_date, end_date, allocation['id'], Summary.end_of_time]))

      result = results[0]
      @mileage += result['mileage'].to_f
      @driver_paid_hours += result['driver_paid_hours'].to_f
      @driver_volunteer_hours += result['driver_volunteer_hours'].to_f
      @escort_volunteer_hours += result['escort_volunteer_hours'].to_f
    end

    def collect_costs_by_trip(allocation, start_date, end_date)
      quarter_where = quarter_sql_fragments(allocation, "trips.date")

      sql = "
select 
sum(fare) as funds, 
sum(customer_pay) as fares, 
0 as agency_other,
0 as vehicle_maint,
0 as donations_fares,
max(allocation_id) as allocation_id
from trips
inner join runs on trips.run_id = runs.base_id and runs.valid_end=?
where
#{quarter_where}
runs.complete=true and 
trips.date between ? and ?
and trips.allocation_id = ?
and trips.valid_end = ? "

      results = ActiveRecord::Base.connection.select_all(bind([sql, Run.end_of_time, start_date, end_date, allocation['id'], Trip.end_of_time]))

      result = results[0]
      @funds += result['funds'].to_f
      @fares += result['fares'].to_f
      @agency_other += result['agency_other'].to_f
      @vehicle_maint += result['vehicle_maint'].to_f
      @donations_fares += result['donations_fares'].to_f

      last_year_sql =  "select
sum(fare) + sum(customer_pay) as total
from trips
inner join runs on runs.base_id = trips.run_id and run.valid_end=?
where
#{quarter_where}
runs.complete=true and 
date between ? and ?
and allocation_id=?
and valid_end = ? "

      results = ActiveRecord::Base.connection.select_all(bind([sql, Run.end_of_time, start_date.prev_year, end_date.prev_year, allocation['id'], Trip.end_of_time]))
      result = results[0]
      @total_last_year += result['total'].to_f
    end

    def collect_costs_by_summary(allocation, start_date, end_date)
      quarter_where = quarter_sql_fragments(allocation, "summaries.period_start")
      sql = "select
sum(funds),
sum(agency_other) as agency_other,
0 as vehicle_maint,
sum(donations) as donations_fares
from summaries 
where 
#{quarter_where}
complete=true and 
period_start >= ? and 
period_end < ? and 
allocation_id=? and 
valid_end = ? "

      results = ActiveRecord::Base.connection.select_all(bind([sql, start_date, end_date, allocation['id'], Summary.end_of_time]))

      result = results[0]
      @funds += result['funds'].to_f
      @agency_other += result['agency_other'].to_f
      @vehicle_maint += result['vehicle_maint'].to_f
      @donations_fares += result['donations_fares'].to_f


      last_year_sql = "select
sum(donations + funds + agency_other) as total
from summaries 
where
#{quarter_where}
complete=true and 
period_start >= ? and 
period_end < ? and 
allocation_id=? and 
valid_end = ? "

      results = ActiveRecord::Base.connection.select_all(bind([sql, start_date.prev_year, end_date.prev_year, allocation['id'], Summary.end_of_time]))
      result = results[0]
      @total_last_year += result['total'].to_f
    end

  end

  @@group_mappings = {
    "agency" => "providers.agency",
    "county" => "allocations.county",
    "funding_source" => "projects.funding_source",
    "funding_subsource" => "projects.funding_subsource",
    "project_name" => "projects.name",
    "project_number" => "projects.project_number",
    "quarter" => "quarter"
  }

  def index

    #network service summary

    groups = "allocations.county,providers.agency"
    group_fields = ['county', 'agency']

    #past two weeks
    end_date = Date.today
    start_date = end_date - 14 
    do_report(groups, group_fields, start_date, end_date, nil, nil)
    @params = {}
    render 'report'
  end


  def show_create_report
    @query = Query.new(params[:q])
    @tags = Allocation.tag_counts
  end

  def show_create_tag
    @providers = Provider.all
    @allocations_with_tag = Set.new()
  end

  def create_tag
    tag_name = params[:tag_name]
    if tag_name.to_s.size == 0
      flash[:notice] = "Need a name for this tag"
      return render show_create_tag
    end

    tag = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name tag_name

    for id in params[:a]
      alloc = Allocation.find(id)
      alloc.tag_list = alloc.tag_list + [tag]
      alloc.save!
    end

    flash[:notice] = "Created"
    return redirect_to :action=>'tag_index'
  end

  def delete_tag
    tag_name = params[:id]
    allocations = Allocation.tagged_with(tag_name)
    for allocation in allocations
      allocation.tag_list.delete tag_name
      allocation.save!
    end
    return redirect_to :action=>'tag_index'
  end

  def show_edit_tag
    @tag_name = params[:id]    
    @providers = Provider.all
    tagged = Allocation.tagged_with(@tag_name).map do |p|
      p.id
    end

    @allocations_with_tag = Set.new(tagged)
  end

  def edit_tag
    tag_name = params[:id]

    tag = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name tag_name

    should_be_tagged = Set.new(params[:a].map do |x| x.to_i end)
    for allocation in Allocation.all
      if should_be_tagged.member? allocation.id
        if ! allocation.tag_list.member? tag_name
          allocation.tag_list = allocation.tag_list + [tag]
        end
      else
        allocation.tag_list.delete tag_name
      end
      allocation.save!
    end

    return redirect_to :action=>'tag_index'

  end

  def tag_index
    @tags = Allocation.tag_counts
  end

  def csv
    query = Query.new(params[:q])
    group_fields = query.group_by

    if group_fields.nil?
      show_create_report
      return render 'show_create_report'
    end

    group_fields = group_fields.split(",")

    groups = group_fields.map { |f| @@group_mappings[f] }

    do_report(groups, group_fields, query.start_date, query.end_date, query.tag, query.fields)
    csv_string = CSV.generate do |csv|
      csv << NetworkReportRow.fields(query.fields)
      apply_to_leaves! group_fields, @results,  do | row |
        csv << row.csv(query.fields)
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
    query = Query.new(params[:q])
    @params = params
    group_fields = query.group_by

    if group_fields.nil?
      show_create_report
      return render 'show_create_report'
    end

    group_fields = group_fields.split(",")

    groups = group_fields.map { |f| @@group_mappings[f] }

    do_report(groups, group_fields, query.start_date, query.end_date, query.tag, query.fields)
  end

  private 

  def plus_three_months(date)
    year = date.year
    month = date.month
    if month >= 10
      month -= 9
      year += 1
    else
      month += 3
    end
    Date.new(year, month, date.day)
  end

  class QuarterAllocation

    def initialize(allocation, quarter_start_date, quarter_end_date)
      @allocation = allocation
      @quarter_start_date=quarter_start_date
      @quarter_end_date=quarter_end_date
      @quarter=quarter_start_date.year * 10 + quarter_start_date.month / 3 + 1

    end

    def quarter
      return @quarter
    end

    def method_missing(method_name, *args, &block)
      @allocation.send method_name, *args, &block
    end

    def respond_to?(method)
      if method == :quarter
        return true
      end
      return @allocation.respond_to? method
    end
  end

  def apply_quarters(allocations, start_date, end_date)
    #enumerate quarters between start_date and end_date
    zero_based_month = start_date.month - 1
    quarter_start = (zero_based_month / 3) * 3 + 1
    year = start_date.year
    quarter_start_date = Date.new(year, quarter_start, 1)

    quarter_end_date = plus_three_months quarter_start_date

    quarters = []
    begin
      quarters += allocations.map do |allocation| 
        QuarterAllocation.new allocation, quarter_start_date, quarter_end_date
      end

      quarter_start_date = plus_three_months quarter_start_date
      quarter_end_date = plus_three_months quarter_end_date
    end while quarter_end_date < end_date

    quarters
  end

  def do_report(groups, group_fields, start_date, end_date, tag, fields)
    group_select = []

    for group,field in groups.split(",").zip group_fields
      group_select << "#{group} as #{field}"
    end

    group_select = group_select.join(",")

    if tag.to_s.size > 0
      results = Allocation.tagged_with(tag).all
    else
      results = Allocation.all
    end

    if group_fields.member? 'quarter'
      results = apply_quarters(results, start_date, end_date)
    end

    allocations = group(group_fields, results)

    apply_to_leaves! group_fields, allocations do | allocationset |

      row = NetworkReportRow.new

      for allocation in allocationset
        row.agency = allocation.agency
        if allocation['trip_collection_method'] == 'trips'
          row.collect_trips_by_trip(allocation, start_date, end_date)
        else
          row.collect_trips_by_summary(allocation, start_date, end_date)
        end

        if allocation['run_collection_method'] == 'trips' or allocation['run_collection_method'] == 'runs'
          row.collect_runs_by_trip(allocation, start_date, end_date)
        else
          row.collect_runs_by_summary(allocation, start_date, end_date)
        end

        if allocation['cost_collection_method'] == 'trips' or allocation['cost_collection_method'] == 'runs'
          row.collect_costs_by_trip(allocation, start_date, end_date)
        else
          row.collect_costs_by_summary(allocation, start_date, end_date)
        end

      end
      row.allocation = allocationset[0]
      row.county = allocationset[0].county
      row.provider_id = allocationset[0].provider_id
      row
    end

    @group_fields = group_fields
    @results = allocations
    @start_date = start_date
    @end_date = end_date
    @tr_open = false
    @fields = fields
    if @fields.nil?
      @fields = {}
      NetworkReportRow.fields.each do |field| 
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

  # group a set of records by a list of fields
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
  # are defined as elements group_fields.size deep, so that hashes
  # can be leaves)
  def apply_to_leaves!(group_fields, group, &block) 
    if group_fields.empty?
      return block.call group
    else
      group.each do |k, v|
        group[k] = apply_to_leaves! group_fields[1..-1], v, &block
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
