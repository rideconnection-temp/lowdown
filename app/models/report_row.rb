def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class ReportRow
  @@attrs = [:allocation, :allocations, :start_date, :after_end_date, :funds, :agency_other, :vehicle_maint, :donations, :total_general_public_cost, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :total_general_public_trips, :customer_trips, :guest_and_attendant_trips, :turn_downs, :undup_riders, :driver_volunteer_hours, :administrative, :operations, :total_elderly_and_disabled_cost]
  attr_accessor *@@attrs

  def numeric_fields
    [:funds, :agency_other, :vehicle_maint, :donations, :total_general_public_cost, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :total_general_public_trips, :customer_trips, :guest_and_attendant_trips, :turn_downs, :driver_volunteer_hours, :undup_riders, :administrative, :operations, :total_elderly_and_disabled_cost]
  end

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

  def initialize(fields_to_show = nil, allocation = nil)
    for field in numeric_fields
      self.instance_variable_set("@#{field}", BigDecimal("0"))
    end
    @fields_to_show = fields_to_show
    @allocations = []
    @allocation = allocation
    @allocations << allocation if allocation.present?
    if allocation.respond_to? "collection_start_date"
      @start_date = allocation.collection_start_date
      @after_end_date   = allocation.collection_after_end_date 
    end
  end

  def total
    # Total cost is the sum of the user-selected constituent cost fields. If no constituent cost 
    # fields are selected, then total cost is the sum of all the constituent cost fields.
    cost_fields = [:funds, :agency_other, :vehicle_maint, :donations, :administrative, :operations]
    cost_fields_to_use = @fields_to_show.map(&:to_sym) & cost_fields if @fields_to_show.present?
    cost_fields_to_use = cost_fields if @fields_to_show.blank? || cost_fields_to_use.blank?

    this_total = 0
    cost_fields_to_use.each{|field| this_total += instance_variable_get("@#{field}") }
    this_total
  end

  # The next four methods are only for the TriMet E&D report. They exist to handle the
  # weirdness of collecting elderly and disable ride counts under different situations and
  # then correlating those trips to costs proportionately.
  def calculate_total_elderly_and_disabled_cost
    # If the total_general_public_trips attribute is present, and we're working with an allocation
    # that collects costs on a summary (not per-trip) basis, which means we need to prorate the
    # total cost based on what portion of the trips are E&D. In this case, total_trips refers to
    # E&D trips only, while total_general_public_trips refers to entire pools of trips in the allocation.

    if total_general_public_trips.present? && 
        total_general_public_trips != 0 &&
        total_general_public_cost == 0
      if total_trips == total_general_public_trips
        @total_elderly_and_disabled_cost = total
      else
        @total_elderly_and_disabled_cost = total * (total_trips.to_f / total_general_public_trips) 
      end
    else
      @total_elderly_and_disabled_cost = total
    end
  end

  def total_non_elderly_and_disabled_cost
    if total_general_public_cost == 0
      total - total_elderly_and_disabled_cost
    else
      total_general_public_cost - total_elderly_and_disabled_cost
    end
  end

  def total_elderly_and_disabled_trips
    # Filtering for E&D was already carried out in the query
    total_trips
  end

  def total_non_elderly_and_disabled_trips
    if total_general_public_trips == 0
      0
    else
      total_general_public_trips - total_elderly_and_disabled_trips
    end
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
    "FY #{allocation.year.to_s}-#{(allocation.year + 1).to_s[-2,2]}"
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
    "#{allocation.period_start_date.strftime("%b %-d")}-#{(allocation.period_after_end_date - 1).strftime("%-d %Y")}"
  end

  def allocation_name
    allocation.name
  end

  def method_missing(method_name)
    if allocation.respond_to?(method_name)
      allocation.send(method_name) 
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    allocation.respond_to?(method_name) || super
  end

  def include_row(row)
    @funds                           += row.funds
    @agency_other                    += row.agency_other
    @vehicle_maint                   += row.vehicle_maint
    @administrative                  += row.administrative
    @operations                      += row.operations
    @donations                       += row.donations
    
    @in_district_trips               += row.in_district_trips
    @out_of_district_trips           += row.out_of_district_trips
    @customer_trips                  += row.customer_trips
    @guest_and_attendant_trips       += row.guest_and_attendant_trips
    @mileage                         += row.mileage

    @driver_volunteer_hours          += row.driver_volunteer_hours
    @driver_paid_hours               += row.driver_paid_hours

    @turn_downs                      += row.turn_downs
    @undup_riders                    += row.undup_riders
    @escort_volunteer_hours          += row.escort_volunteer_hours
    @admin_volunteer_hours           += row.admin_volunteer_hours

    @total_general_public_trips      += row.total_general_public_trips
    @total_general_public_cost       += row.total_general_public_cost
    @total_elderly_and_disabled_cost += row.total_elderly_and_disabled_cost

    @allocations                      = (@allocations + row.allocations).uniq
    if @start_date.present?
      @start_date = row.start_date if row.start_date && @start_date > row.start_date
    else 
      @start_date = row.start_date
    end
    if @after_end_date.present?
      @after_end_date = row.after_end_date if row.after_end_date && @after_end_date < row.after_end_date
    else 
      @after_end_date = row.after_end_date
    end
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

  def collect_trips_by_trip(allocation, start_date, after_end_date, options = {})
    results = Trip.select("sum(case when in_trimet_district=true and result_code = 'COMP' then 1 + guest_count + attendant_count else 0 end) as in_district_trips, sum(case when in_trimet_district=false and result_code = 'COMP' then 1 + guest_count + attendant_count else 0 end) as out_of_district_trips, sum(case when result_code = 'COMP' then 1 else 0 end) as customer_trips, sum(case when result_code = 'COMP' then guest_count + attendant_count else 0 end) as guest_and_attendant_trips, sum(case when result_code='TD' then 1 + guest_count + attendant_count else 0 end) as turn_downs")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'
    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)

    # Get the total number of new customers who haven't been served in prior months of this fiscal year 
    # (starting July 1). Relies on custom Postgres functions fiscal_year and fiscal_month, which shift 
    # dates ahead by six months to make date filtering easier.
    special_where = ""
    special_where = "complete=true and " if options[:pending]
    if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'
      special_where = special_where + "customer_type='Honored' and " 
    end
    undup_riders_sql = %Q[
        SELECT COUNT(*) AS undup_riders
        FROM (
          SELECT customer_id, fiscal_year(date) AS year, MIN(fiscal_month(date)) AS month
          FROM trips
          WHERE #{special_where}allocation_id=? AND valid_end=? AND result_code = 'COMP'
          GROUP BY customer_id, year) AS morx
        WHERE date (year || '-' || month || '-' || 1) >= ? and date (year || '-' || month || '-' || 1) < ?
      ]
    row = ActiveRecord::Base.connection.select_one(bind([
        undup_riders_sql,
        allocation['id'],
        Trip.end_of_time,
        start_date.advance(:months=>6),
        after_end_date.advance(:months=>6)
      ]))
    add_results['undup_riders'] = row['undup_riders'].to_i

    # Collect the total_general_public_trips only if we're dealing with a service that's 
    # not strictly for elderly and disabled customers.
    # This will be used to create a ratio of E&D to total trips so that we can calculate costs for the TriMet E&D report.
    if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'
      results = Trip.select("SUM(CASE WHEN result_code = 'COMP' THEN 1 + guest_count + attendant_count ELSE 0 END) AS total_general_public_trips")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless options[:pending]
      row = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
      add_results['total_general_public_trips'] = row['total_general_public_trips'].to_i
    end
    apply_results(add_results)
  end

  def collect_trips_by_summary(allocation, start_date, after_end_date, options = {})
    results = Summary.select("sum(in_district_trips) as in_district_trips, sum(out_of_district_trips) as out_of_district_trips")
    results = results.where(:allocation_id => allocation['id']).joins(:summary_rows)
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
    apply_results(add_results)

    results = Summary.select("SUM(turn_downs) AS turn_downs, SUM(unduplicated_riders) as undup_riders")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
    apply_results(add_results)

    # Collect the total_general_public_trips only if we're dealing with a service that's 
    # not strictly for elderly and disabled customers.  This will be used in the E&D audit export
    if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'
      results = Summary.select("SUM(in_district_trips) + SUM(out_of_district_trips) as total_general_public_trips")
      results = results.where(:allocation_id => allocation['id']).joins(:summary_rows)
      results = results.data_entry_complete unless options[:pending]
      row = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
      add_results['total_general_public_trips'] = row['total_general_public_trips'].to_i
      apply_results(add_results)
    end
  end

  def collect_runs_by_trip(allocation, start_date, after_end_date, options = {})
    results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/3600.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/3600.0 as driver_volunteer_hours, 0 as escort_volunteer_hours")
    results = results.completed.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_runs_by_run(allocation, start_date, after_end_date, options = {})
    results = Trip.select("sum(apportioned_mileage) as mileage, sum(case when COALESCE(volunteer_trip,false)=false then apportioned_duration else 0 end)/3600.0 as driver_paid_hours, sum(case when volunteer_trip=true then apportioned_duration else 0 end)/3600.0 as driver_volunteer_hours, sum(COALESCE((SELECT escort_count FROM runs where id = trips.run_id),0) * apportioned_duration)/3600.0 as escort_volunteer_hours")
    results = results.completed.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_runs_by_summary(allocation, start_date, after_end_date, options = {})
    results = Summary.select("sum(total_miles) as mileage, sum(driver_hours_paid) as driver_paid_hours, sum(driver_hours_volunteer) as driver_volunteer_hours, sum(escort_hours_volunteer) as escort_volunteer_hours")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_costs_by_trip(allocation, start_date, after_end_date, options = {})
    results = Trip.select("sum(apportioned_fare) as funds, 0 as agency_other, 0 as donations")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'
    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)

    # Collect the total_general_public_cost only if we're dealing with a service that's 
    # not strictly for elderly and disabled customers. This is used for audit purposes.
    if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'
      results = Trip.select("sum(apportioned_fare) AS total_general_public_cost")
      results = results.where(:allocation_id => allocation['id'])
      results = results.data_entry_complete unless options[:pending]
      row = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
      add_results['total_general_public_cost'] = BigDecimal(row['total_general_public_cost']) unless row['total_general_public_cost'].blank?
    end

    apply_results(add_results)
  end

  def collect_costs_by_summary(allocation, start_date, after_end_date, options = {})
    results = Summary.select("sum(funds) as funds, sum(agency_other) as agency_other, sum(donations) as donations")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]

    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
    apply_results(add_results)
  end

  def collect_operation_data_by_summary(allocation, start_date, after_end_date, options = {})
    results = Summary.select("sum(operations) as operations, sum(administrative) as administrative, sum(vehicle_maint) as vehicle_maint, sum(administrative_hours_volunteer) as admin_volunteer_hours")
    results = results.where(:allocation_id => allocation['id'])
    results = results.data_entry_complete unless options[:pending]
    results = results.where("1 = 2") if options[:elderly_and_disabled_only] && allocation.eligibility != 'Elderly & Disabled'

    add_results = results.current_versions.date_range(start_date, after_end_date).first.try(:attributes)
    apply_results(add_results)
  end

end
