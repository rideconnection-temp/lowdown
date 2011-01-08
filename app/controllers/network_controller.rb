class NetworkController < ApplicationController

  class NetworkReportRow
    attr_accessor :allocation, :county, :funds, :fares, :agency_other, :vehicle_maint, :donations_fares, :escort_volunteer_hours, :admin_volunteer_hours, :volunteer_hours, :paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :undup_riders, :driver_volunteer_hours

    def numeric_fields
      return [:funds, :fares, :agency_other, :vehicle_maint, :donations_fares, :escort_volunteer_hours, :admin_volunteer_hours, :volunteer_hours, :paid_hours, :total_trips, :mileage, :in_district_trips, :out_of_district_trips, :turn_downs, :undup_riders, :driver_volunteer_hours]
    end

    def initialize(hash)

      if hash.nil?
        for k in numeric_fields
          self.instance_variable_set("@#{k}", 0.0)  # create and initialize an instance variable for this field
        end
            
        return #this is a summary row because do not set up anything further
      end
        

      for field in numeric_fields
        hash[field.to_s] = hash[field.to_s].to_f
      end

      hash.each do |k,v|
        self.instance_variable_set("@#{k}", v)  # create and initialize an instance variable for this key/value pair
      end

      self.allocation = Allocation.find(@allocation_id)
    end

    def county
      return @allocation.county
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
      # @admin_volunteer_hours += ???
    end

  end

  def index

    #this SQL is for trips which are accounted by trip rather than by run

    #totals grouped by county, provider
    #totals grouped by county
    fields = "
allocations.county, 
allocations.provider_id, 
sum(trips.fare) as funds, 
sum(trips.customer_pay) as fares, 
sum(trips.odometer_end - trips.odometer_start) as mileage, 
sum(trips.duration) as paid_hours,
sum(case when trips.in_trimet_district=true then 1 else 0 end) as in_district_trips,
sum(case when trips.in_trimet_district=false then 1 else 0 end) as out_of_district_trips,
count(*) as total_trips,
sum(case when trips.result_code='TD' then 1 else 0 end) as turn_downs,
count(distinct customer_id) as undup_riders,
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
inner join allocations on allocations.id = trips.allocation_id inner join runs on runs.id = trips.run_id 
group by allocations.county, allocations.provider_id
"

    results = ActiveRecord::Base.connection.select_all(sql)

    #now, split up rows into groups
    counties = []
    for result in results
      result = NetworkReportRow.new(result)

      if counties.empty? or result.allocation.county != counties[-1][-1].allocation.county
        counties << []
      end
      cur_county = counties[-1]
      cur_county << result
    end

    @counties = counties
  end

  def sum(rows)
    out = NetworkReportRow.new(nil)
    rows.each do |row|
      out.include_row(row)
    end
    return out
  end

end
