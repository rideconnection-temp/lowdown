class NetworkController < ApplicationController
  class NetworkReportRow
    attr_accessor :allocation, :funds, :fares, :agency_other, :vehicle_maint
    attr_accessor :donations_fares, :in_district_trips, :out_of_district_trips
    attr_accessor :total_this_period, :total_last_year_period, :mileage
    attr_accessor :volunteer_hours, :paid_hours, :total_miles, :turn_downs
    attr_accessor :undup_riders, :escort_volunteer_hours, :admin_volunteer_hours

    def initialize(trip)
      @allocation = trip.allocation

      @funds = 0
      @fares = 0

      #these will be zero for now, because they do not apply to taxis
      @agency_other = 0
      @vehicle_maint = 0
      @donations_fares = 0

      @in_district_trips = 0
      @out_of_district_trips = 0
      @total_this_period = 0
      @total_last_year_period = 0
      @mileage = 0
      @volunteer_hours = 0
      @paid_hours = 0

      @total_miles = 0

      @turn_downs = 0
      @undup_riders = Set.new
      @escort_volunteer_hours = 0
      @admin_volunteer_hours = 0
    end

    def county
      return @allocation.county
    end

    def total
      return @funds + @fares + @agency_other + @vehicle_maint + @donations_fares
    end

    def total_hours
      return @paid_hours + @volunteer_hours
    end

    def cost_per_hour
      return @funds / total_hours
    end

    def cost_per_trip
      return @funds / total_trips
    end

    def cost_per_mile
      return @funds / @mileage
    end

    def total_trips
      return @in_district_trips + @out_of_district_trips
    end

    def total_volunteer_hours
      return @escort_volunteer_hours + @admin_volunteer_hours
    end

    def include(trip)
      @funds += trip.fare
      @fares += trip.customer_pay

      @in_district_trips += trip.in_trimet_district ? 1 : 0
      @out_of_district_trips += trip.in_trimet_district ? 0 : 1

      @mileage += trip.odometer_end - trip.odometer_start

      @paid_hours += (trip.end_at - trip.start_at) / 3600.0

      @turn_downs += trip.result_code == "TD" ? 1 : 0
      @undup_riders << trip.customer_id

      run = trip.run
      if run != nil
        @escort_volunteer_hours += run.escort_count * (trip.end_at - trip.start_at) / 3600.0
      end
      # @admin_volunteer_hours += ???
    end

    def includeRow(row)
      @funds += row.funds
      @fares += row.fares

      @in_district_trips += row.in_district_trips
      @out_of_district_trips += row.out_of_district_trips

      @mileage += row.mileage

      @paid_hours += row.paid_hours

      @turn_downs += row.turn_downs
      @undup_riders += row.undup_riders

      @escort_volunteer_hours += row.escort_volunteer_hours
      # @admin_volunteer_hours += ???
    end

  end
  def index
    #we want to do our work of ordering things here.
    #what we have is a list of counties, each of which
    #has a list of providers, each with a looooong summary row


    #so, these could actually be, for trips, complex
    #aggregate queries, but we may choose not to do this
    #because it's faster to do it in Ruby.  We'll try it in
    #ruby then we'll try more advanced nonsense

    #let's say we're ordered by county, then provider

    trips = Trip.current_versions.includes(:allocation, :run).joins(:allocation).order("allocations.county, trips.allocation_id")

    #now, split up trips into groups
    counties = []
    for trip in trips
      allocation = trip.allocation
      if counties.empty? or allocation.county != counties[-1][-1].allocation.county
        counties << []
      end
      cur_county = counties[-1]
      if cur_county.empty? or trip.allocation != cur_county[-1].allocation
        cur_county << NetworkReportRow.new(trip)
      end
      cur_county[-1].include(trip)
    end

    @counties = counties
  end

  def sum(rows)
    out = NetworkReportRow.new(rows[0])
    rows.each do |row|
      out.includeRow(row)
    end
    return out
  end

end
