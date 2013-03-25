def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class ReportRow
  @@attrs = [:allocation, :funds, :agency_other, :vehicle_maint, :donations, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :customer_trips, :guest_and_attendant_trips, :turn_downs, :undup_riders, :driver_volunteer_hours, :total_last_year, :administrative, :operations]
  attr_accessor *@@attrs

  def numeric_fields
    return [:funds, :agency_other, :vehicle_maint, :donations, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :customer_trips, :guest_and_attendant_trips, :turn_downs, :driver_volunteer_hours, :total_last_year, :undup_riders, :administrative, :operations]
  end

  @@selector_fields = ['allocation', 'county', 'provider_id', 'project_name']

  def self.fields(requested_fields=nil)
    if requested_fields.nil? || requested_fields.empty?
      fields = @@attrs.map { |x| x.to_s } + ["cost_per_hour", "cost_per_mile", "cost_per_trip", "miles_per_ride", "cost_per_customer", "miles_per_customer"]
    else
      all_fields = @@attrs.map { |x| x.to_s }
      fields = all_fields & requested_fields
    end
    fields.delete 'driver_hours'
    fields.delete 'volunteer_hours'
    fields
  end

  def self.sum(rows, out=nil, results_fields=nil)
    out ||= ReportRow.new(results_fields)

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
    # Total cost is the sum of the user-selected constituent cost fields. If no constituent cost 
    # fields are selected, then total cost is the sum of all the constituent cost fields.
    cost_fields = [:funds, :agency_other, :vehicle_maint, :donations, :administrative, :operations]
    cost_fields_to_use = @fields_to_show.map(&:to_sym) & cost_fields if @fields_to_show.present?
    cost_fields_to_use = cost_fields if @fields_to_show.blank? || cost_fields_to_use.blank?

    total = 0
    cost_fields_to_use.each{|field| total += instance_variable_get("@#{field}") }
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

  def cost_per_trip
    if total_trips == 0
      nil
    else
      total / total_trips
    end
  end

  def cost_per_customer
    if customer_trips == 0
      nil
    else
      total / customer_trips
    end
  end

  def cost_per_mile
    if @mileage == 0
      nil
    else
      total / @mileage
    end
  end

  def cost_per_hour
    if driver_total_hours == 0
      nil
    else
      total / driver_total_hours
    end
  end

  def miles_per_ride
    if total_trips == 0
      nil
    else
      @mileage / total_trips
    end
  end

  def miles_per_customer
    if customer_trips == 0
      nil
    else
      @mileage / customer_trips
    end
  end

  def year
    allocation.year.to_s
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

  def month
    m = allocation.month.to_s
    this_year = m[0...4].to_i
    this_month = m[4..5].to_i

    Date.new(this_year, this_month, 1).strftime "%b %Y"
  end

  def semimonth
    "#{allocation.period_start_date.strftime("%b %-d")}-#{(allocation.period_end_date - 1).strftime("%-d %Y")}"
  end

  def allocation_name
    allocation.name
  end

  def project_number
    allocation.project_number
  end

  def program_name
    allocation.program_name
  end

  def funding_source
    allocation.funding_source
  end

  def funding_subsource
    allocation.funding_subsource
  end

  def project_name
    allocation.project_name
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
    allocation.reporting_agency_name
  end

  def short_reporting_agency_name
    allocation.reporting_agency.try :short_name
  end

  def provider_id
    allocation.provider_id
  end

  def provider_name
    allocation.provider_name
  end

  def short_provider_name
    allocation.provider.try :short_name
  end
  
  def trimet_provider_name 
    allocation.trimet_provider_name
  end

  def trimet_provider_identifier 
    allocation.trimet_provider_identifier
  end

  def trimet_program_name
    allocation.trimet_program_name
  end

  def trimet_program_identifier
    allocation.trimet_program_identifier
  end

  def trimet_report_group_name
    allocation.trimet_report_group_name
  end

  def include_row(row)
    @funds                      += row.funds
    @agency_other               += row.agency_other
    @vehicle_maint              += row.vehicle_maint
    @administrative             += row.administrative
    @operations                 += row.operations
    @donations                  += row.donations
    
    @in_district_trips          += row.in_district_trips
    @out_of_district_trips      += row.out_of_district_trips
    @total_last_year            += row.total_last_year
    @customer_trips             += row.customer_trips
    @guest_and_attendant_trips  += row.guest_and_attendant_trips
    @mileage                    += row.mileage

    @driver_volunteer_hours     += row.driver_volunteer_hours
    @driver_paid_hours          += row.driver_paid_hours

    @turn_downs                 += row.turn_downs
    @undup_riders               += row.undup_riders
    @escort_volunteer_hours     += row.escort_volunteer_hours
    @admin_volunteer_hours      += row.admin_volunteer_hours
  end

  def apply_results(add_result)
    add_result.keys.each do |field|
      if add_result[field].present?
        var = "@#{field}"
        new = instance_variable_get var
        new += BigDecimal(add_result[field].to_s) 
        instance_variable_set var, new
      end
    end
  end

  def collect_trips_by_trip(allocation, start_date, end_date, options = {})
    results = Trip.select("sum(case when in_trimet_district=true and result_code = 'COMP' then 1 + guest_count + attendant_count else 0 end) as in_district_trips, sum(case when in_trimet_district=false and result_code = 'COMP' then 1 + guest_count + attendant_count else 0 end) as out_of_district_trips, sum(case when result_code = 'COMP' then 1 else 0 end) as customer_trips, sum(case when result_code = 'COMP' then guest_count + attendant_count else 0 end) as guest_and_attendant_trips, sum(case when result_code='TD' then 1 + guest_count + attendant_count else 0 end) as turn_downs")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)

    pending_where = options[:pending] ? "" : "complete=true and " 
    undup_riders_sql = "select count(*) as undup_riders from (select customer_id, fiscal_year(date) as year, min(fiscal_month(date)) as month from trips where #{pending_where}allocation_id=? and valid_end=? and result_code = 'COMP' group by customer_id, year) as morx where date (year || '-' || month || '-' || 1) >= ? and date (year || '-' || month || '-' || 1) < ? "
    row = ActiveRecord::Base.connection.select_one(bind([undup_riders_sql, allocation['id'], Trip.end_of_time, start_date.advance(:months=>6), end_date.advance(:months=>6)]))
    add_results['undup_riders'] = row['undup_riders'].to_i
    apply_results(add_results)
  end

  def collect_trips_by_summary(allocation, start_date, end_date, options = {})
    results = Summary.select("sum(in_district_trips) as in_district_trips, sum(out_of_district_trips) as out_of_district_trips")
    results = results.where(:allocation_id => allocation['id']).joins(:summary_rows)
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)

    results = Summary.select("SUM(turn_downs) AS turn_downs, SUM(unduplicated_riders) as undup_riders")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_runs_by_trip(allocation, start_date, end_date, options = {})
    results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/3600.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/3600.0 as driver_volunteer_hours, 0 as escort_volunteer_hours")
    results = results.completed.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_runs_by_run(allocation, start_date, end_date, options = {})
    results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/3600.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/3600.0 as driver_volunteer_hours, sum(COALESCE((SELECT escort_count FROM runs where id = trips.run_id),0) * apportioned_duration)/3600.0 as escort_volunteer_hours")
    results = results.completed.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_runs_by_summary(allocation, start_date, end_date, options = {})
    results = Summary.select("sum(total_miles) as mileage, sum(driver_hours_paid) as driver_paid_hours, sum(driver_hours_volunteer) as driver_volunteer_hours, sum(escort_hours_volunteer) as escort_volunteer_hours")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_costs_by_trip(allocation, start_date, end_date, options = {})
    results = Trip.select("sum(apportioned_fare) as funds, 0 as agency_other, 0 as donations")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_costs_by_summary(allocation, start_date, end_date, options = {})
    results = Summary.select("sum(funds) as funds, sum(agency_other) as agency_other, sum(donations) as donations")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_operation_data_by_summary(allocation, start_date, end_date, options = {})
    results = Summary.select("sum(operations) as operations, sum(administrative) as administrative, sum(vehicle_maint) as vehicle_maint, sum(administrative_hours_volunteer) as admin_volunteer_hours")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, end_date).first.try(:attributes)
    apply_results(add_results)
  end

end
