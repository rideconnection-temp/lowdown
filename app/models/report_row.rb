def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class ReportRow
  @@attrs = [:allocation, :allocations, :start_date, :after_end_date, :funds, :agency_other, :vehicle_maint, :donations, :total_general_public_cost, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :total_general_public_trips, :customer_trips, :guest_and_attendant_trips, :volunteer_driver_trips, :trips_marked_as_volunteer, :turn_downs, :no_shows, :cancellations, :unmet_need, :other_results, :total_requests, :undup_riders, :driver_volunteer_hours, :administrative, :operations, :total_elderly_and_disabled_cost]
  attr_accessor *@@attrs

  def numeric_fields
    [:funds, :agency_other, :vehicle_maint, :donations, :total_general_public_cost, :escort_volunteer_hours, :admin_volunteer_hours, :driver_paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :total_general_public_trips, :customer_trips, :guest_and_attendant_trips, :volunteer_driver_trips, :trips_marked_as_volunteer, :turn_downs, :no_shows, :cancellations, :unmet_need, :other_results, :total_requests, :driver_volunteer_hours, :undup_riders, :administrative, :operations, :total_elderly_and_disabled_cost]
  end

  def self.trip_fields
    [:in_district_trips, :out_of_district_trips, :total_trips, :customer_trips, :guest_and_attendant_trips, :volunteer_driver_trips, :trips_marked_as_volunteer, :turn_downs, :no_shows, :cancellations, :unmet_need, :other_results, :total_requests, :undup_riders, :total_general_public_trips, :cost_per_trip, :cost_per_customer, :miles_per_ride, :miles_per_customer]
  end

  def self.run_fields
    [:mileage, :driver_paid_hours, :driver_volunteer_hours, :escort_volunteer_hours, :cost_per_hour, :cost_per_mile, :miles_per_ride, :miles_per_customer]
  end

  def self.cost_fields
    [:funds, :agency_other, :donations, :total, :total_general_public_cost, :total_elderly_and_disabled_cost, :cost_per_hour, :cost_per_mile, :cost_per_trip, :cost_per_customer]
  end

  def self.operations_fields
    [:operations, :administrative, :vehicle_maint, :admin_volunteer_hours]
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

  def total_requests
    total_trips + @turn_downs + @no_shows + @cancellations + @unmet_need + @other_results
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

  def diff(other)
    unequal_fields = {}
    numeric_fields.each do |fld|
      unequal_fields[fld] = (send(fld) - other.send(fld).to_f) unless send(fld) == other.send(fld)
    end
    unequal_fields
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
    @trips_marked_as_volunteer       += row.trips_marked_as_volunteer
    @volunteer_driver_trips                 += row.volunteer_driver_trips

    @mileage                         += row.mileage

    @driver_volunteer_hours          += row.driver_volunteer_hours
    @driver_paid_hours               += row.driver_paid_hours

    @turn_downs                      += row.turn_downs
    @no_shows                        += row.no_shows
    @cancellations                   += row.cancellations
    @unmet_need                      += row.unmet_need
    @other_results                   += row.other_results
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

  def calculate_fields!
    calculate_volunteer_driver_trips!
  end

  private

  def calculate_volunteer_driver_trips!
    case allocation.driver_type_collection_method
    when 'all volunteer'
      @volunteer_driver_trips = total_trips
    when 'all paid'
      @volunteer_driver_trips = BigDecimal('0')
    when 'mixed'
      case trip_collection_method
      when 'trips'
        # For allocations with trip details that have both volunteer and paid drivers,
        # rely on the 'volunteer_run' field of the runs table to tell us which trips
        # are volunteer
        @volunteer_driver_trips = @trips_marked_as_volunteer
      when 'summary'
        # For summary allocations that have both volunteer and paid drivers,
        # use the ratio of volunteer driver hours to total volunteer hours to give
        # the best possible approximation
        if driver_total_hours > 0
          @volunteer_driver_trips = (driver_volunteer_hours.fdiv(driver_total_hours) * (@in_district_trips + @out_of_district_trips)).to_i
        else
          @volunteer_driver_trips =  BigDecimal('0')
        end
      when 'none'
        @volunteer_driver_trips =  BigDecimal('0')
      end
    end
  end

end
