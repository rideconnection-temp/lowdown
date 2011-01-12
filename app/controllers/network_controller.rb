class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date
  attr_accessor :end_date
  attr_accessor :group_by

  def convert_date(obj, base)
    return Date.new(obj["#{base}(1i)"].to_i,obj["#{base}(2i)"].to_i,obj["#{base}(3i)"].to_i)
  end

  def initialize(params)
    if params
      if params["start_date(1i)"]
        @start_date = convert_date(params, :start_date)
      end
      if params["end_date(1i)"]
        @end_date = convert_date(params, :end_date)
      end
      if params[:group_by]
        @group_by = params[:group_by]
      end
    end
  end

  def persisted?
    false
  end

end


class NetworkController < ApplicationController

  class NetworkReportRow
    attr_accessor :allocation, :county, :provider_id, :funds, :fares, :agency_other, :vehicle_maint, :donations_fares, :escort_volunteer_hours, :admin_volunteer_hours, :volunteer_hours, :paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :undup_riders, :driver_volunteer_hours

    def numeric_fields
      return [:funds, :fares, :agency_other, :vehicle_maint, :donations_fares, :escort_volunteer_hours, :admin_volunteer_hours, :volunteer_hours, :paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :driver_volunteer_hours]
    end

    def initialize(hash)

      if hash.nil?
        for k in numeric_fields
          self.instance_variable_set("@#{k}", 0.0)
        end

        @undup_riders = Set.new
        return #because this is a summary row, do not set up anything further
      end

      for field in numeric_fields
        hash[field.to_s] = hash[field.to_s].to_f
      end

      hash.each do |k,v|
        self.instance_variable_set("@#{k}", v)
      end

      self.allocation = Allocation.find(@allocation_id)
    end

    def total
      return @funds + @fares + @agency_other + @vehicle_maint + @donations_fares
    end

    def total_hours
      return paid_hours + total_volunteer_hours
    end

    def total_volunteer_hours
      return escort_volunteer_hours + admin_volunteer_hours
    end

    def total_trips
      return @in_district_trips + @out_of_district_trips
    end

    def cost_per_hour
      return @funds / total_hours
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

    def include_row(row)
      @funds += row.funds
      @fares += row.fares

      @in_district_trips += row.in_district_trips
      @out_of_district_trips += row.out_of_district_trips

      @mileage += row.mileage

      @paid_hours += row.paid_hours

      @turn_downs += row.turn_downs
      @undup_riders += row.undup_riders

      @escort_volunteer_hours += row.escort_volunteer_hours
    end

  end

  @@group_mappings = {

"county,provider_id" => "allocations.county, allocations.provider_id", 
"funding_source,county,provider,project_name" => "projects.funding_source, allocations.county, allocations.provider_id, projects.name"
  }

  # group a set of records by a list of fields
  def group(groups, records)
    out = {}
    last_group = groups[-1]

    for record in records
      cur_group = out
      for group in groups
        if group == last_group
          if !cur_group.member? record[group]
            cur_group[record[group]] = []
          end
        else
          if ! cur_group.member? record[group]
            cur_group[record[group]] = {}
          end
        end
        cur_group = cur_group[record[group]]
      end
      cur_group << record
    end
    return out
  end

  def index

    #network service summary

    #this SQL is for trips which are accounted by trip rather than by run
    groups = "allocations.county,allocations.provider_id"
    group_fields = ['county', 'provider_id']

    do_report(groups, group_fields)
    render 'report'
  end

  def report
    group_fields = params['group_by']
    groups = @@group_mappings[group_fields]

    group_fields = group_fields.split(",")

    do_report(groups, group_fields)
  end


  def show_create_report
    @query = Query.new(nil)
  end

  def do_report(groups, group_fields)

    fields = "
allocations.county as county, 
allocations.provider_id as provider_id, 
sum(trips.fare) as funds, 
sum(trips.customer_pay) as fares, 
sum(trips.odometer_end - trips.odometer_start) as mileage, 
sum(trips.duration) as paid_hours,
sum(case when trips.in_trimet_district=true then 1 else 0 end) as in_district_trips,
sum(case when trips.in_trimet_district=false then 1 else 0 end) as out_of_district_trips,
count(*) as total_trips,
sum(case when trips.result_code='TD' then 1 else 0 end) as turn_downs,
0 as agency_other,
0 as vehicle_maint,
0 as donations_fares,
0 as driver_volunteer_hours,
sum(runs.escort_count * trips.duration) as escort_volunteer_hours,
0 as admin_volunteer_hours,
max(allocation_id) as allocation_id
"
    sql = "select 
#{fields}
from trips
inner join allocations on allocations.id = trips.allocation_id 
inner join runs on runs.id = trips.run_id 
inner join projects on allocations.project_id = projects.id 
group by #{groups}
"

    distinct_riders_sql = "select distinct customer_id, #{groups} from trips
inner join allocations on allocations.id = trips.allocation_id
inner join projects on allocations.project_id = projects.id 
group by #{groups}, customer_id"

    distinct_riders_results = group(group_fields, ActiveRecord::Base.connection.select_all(distinct_riders_sql))

    results = ActiveRecord::Base.connection.select_all(sql)

    results = group(group_fields, results)

    apply_to_leaves! group_fields, results do | result |
      result = NetworkReportRow.new(result[0])
      undup_riders = get_by_key group_fields, distinct_riders_results, result
      result.undup_riders = Set.new undup_riders
      result
    end

    @counties = results
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
      hash = hash[val]
    end
    return hash
  end

  def sum(rows)
    out = NetworkReportRow.new(nil)
    rows.each do |row|
      out.include_row(row)
    end
    return out
  end

end
