def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

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

  def self.sum(rows, out=nil)
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

  def initialize(fields_to_show = nil)
    for field in numeric_fields
      self.instance_variable_set("@#{field}", BigDecimal("0"))
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
    m = allocation.month.to_s
    this_year = m[0...4].to_i
    this_month = m[4..5].to_i

    Date.new(this_year, this_month, 1).strftime "%b %Y"
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

  def county
    allocation.county
  end
  
  def short_county
    allocation.short_county
  end
  
  def reporting_agency_id
    allocation.reporting_agency_id
  end

  def reporting_agency_name
    allocation.reporting_agency.try :name
  end

  def short_reporting_agency_name
    allocation.reporting_agency.try :short_name
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
      new = instance_variable_get var
      new += BigDecimal(add_result[field].to_s) if add_result[field].present?
      new -= BigDecimal(subtract_result[field].to_s) if subtract_result[field].present?
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
      undup_riders_sql = "select count(*) as undup_riders from (select customer_id, fiscal_year(date) as year, min(fiscal_month(date)) as month from trips where #{pending_where}allocation_id=? and valid_end=? and result_code = 'COMP' group by customer_id, year) as morx where date (year || '-' || month || '-' || 1) >= ? and date (year || '-' || month || '-' || 1) < ? "
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
    results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/3600.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/3600.0 as driver_volunteer_hours, 0 as escort_volunteer_hours")
    results = results.completed.where(:allocation_id => allocation['id'])
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
    results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/3600.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/3600.0 as driver_volunteer_hours, sum(COALESCE((SELECT escort_count FROM runs where id = trips.run_id),0) * apportioned_duration)/3600.0 as escort_volunteer_hours")
    results = results.completed.where(:allocation_id => allocation['id'])
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
    results = Summary.select("sum(total_miles) as mileage, sum(driver_hours_paid) as driver_paid_hours, sum(driver_hours_volunteer) as driver_volunteer_hours, sum(escort_hours_volunteer) as escort_volunteer_hours")
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
    results = Trip.select("sum(apportioned_fare) as funds, 0 as agency_other, 0 as donations")
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
    results = Summary.select("sum(operations) as operations, sum(administrative) as administrative, sum(vehicle_maint) as vehicle_maint, sum(administrative_hours_volunteer) as admin_volunteer_hours")
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
