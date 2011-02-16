class CustomersController < ApplicationController

  before_filter :require_user

  def show_create_report

  end

  def report
    @start_date = Date.parse(params[:date])
    @end_date = @start_date.next_month

    trips = Trip.joins(:allocation=>:project).where("date between ? and ? and valid_end = ? and funding_source='SPD'", @start_date, @end_date, Trip.end_of_time)

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

      key = [trip.customer_id, wheelchair]
      customer = trip.customer
      row = @customer_rows[key]
      if row.nil?
        row = {:customer => customer,
               :billed_rides=>0, :billable_mileage=>0, :mobility=>wheelchair}
        @customer_rows[key] = row
      end

      row[:billed_rides] += 1
      mileage = trip.estimated_trip_distance_in_miles
      if mileage < 5
        rounded_mileage = 0
      elsif mileage < 25
        rounded_mileage = mileage - 5
      else
        rounded_mileage = 20
      end

      row[:billable_mileage] += rounded_mileage

      @approved_rides += customer.approved_rides.to_i
      if wheelchair == "unknown"
        @unknown_billed_rides += 1
        @unknown_mileage += rounded_mileage
      elsif wheelchair
        @wc_billed_rides += 1
        @wc_mileage += rounded_mileage
      else
        @nonwc_billed_rides += 1
        @nonwc_mileage += rounded_mileage
      end
    end

  end
end
