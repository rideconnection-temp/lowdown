class ReportQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date, :end_date, :after_end_date, :provider_id, :provider, :county

  def initialize(params = {})
    params = {} if params.nil?
    now = Date.today
    if params[:start_date]
      @start_date = params[:start_date].to_date
    elsif params['start_date(1i)']
      @start_date = date_from_params(params,:start_date)
    elsif params[:date_range] == :quarter
      @start_date = Date.new(now.year, (now.month-1)/3*3+1,1) - 3.months
    elsif params[:date_range] == :fiscal_year_to_date
      if (now - 1.month).month > 6
        @start_date = Date.new(now.year, 7, 1)
      else
        @start_date = Date.new(now.year - 1, 7, 1)
      end
    else
      @start_date = Date.new(now.year, now.month, 1).prev_month
    end

    if params[:end_date]
      @end_date = params[:end_date].to_date
      @after_end_date = @end_date + 1.day
    elsif params['end_date(1i)']
      @after_end_date = date_from_params(params,:end_date) + 1.month
      @end_date = @after_end_date - 1.day
    elsif params[:date_range] == :quarter
      @after_end_date = @start_date + 3.months
      @end_date = @after_end_date - 1.day
    elsif params[:date_range] == :fiscal_year_to_date
      @after_end_date = Date.new(now.year,now.month,1)
      @end_date = @after_end_date - 1.day
    else
      @after_end_date = @start_date + 1.month
      @end_date = @after_end_date - 1.day
    end

    @provider = params[:provider]             if params[:provider].present?
    @provider_id = params[:provider_id].to_i  if params[:provider_id].present?
    @county = params[:county]                 if params[:county].present?
  end

  def persisted?
    false
  end

  private

  def date_from_params(params_in,attribute_name)
    Date.new( params_in["#{attribute_name}(1i)"].to_i, params_in["#{attribute_name}(2i)"].to_i, params_in["#{attribute_name}(3i)"].to_i ) 
  end
end

def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class PredefinedReportsController < ApplicationController
  require 'csv'

  def index
    @query = ReportQuery.new
    @quarterly_query = ReportQuery.new(:date_range => :quarter)
    @fiscal_year_to_date_query = ReportQuery.new(:date_range => :fiscal_year_to_date)
  end

  def premium_service_billing
    @query = ReportQuery.new(params[:report_query])
    trips = Trip.current_versions.completed.date_range(@query.start_date,@query.after_end_date).includes(:customer,{:allocation => :provider},:pickup_address,:dropoff_address).default_order
    trips = trips.for_provider(@query.provider_id) if @query.provider_id.present?
    case @query.county
    when "Multnomah"
      trips = trips.multnomah_ads
      @title = "Multnomah County ADS Premium Service Report"
    when "Washington"
      trips = trips.washington_davs
      @title = "Washington County DAVS Premium Service Report"
    else
      redirect_to :controller => :predefined_reports, :action => :index
    end
    trips_billed_per_hour = trips.billed_per_hour
    @trips_billed_per_trip = trips.billed_per_trip
    all_trips = trips_billed_per_hour + @trips_billed_per_trip
    @run_groups = trips_billed_per_hour.group_by(&:run)

    @total_taxi_cost      = all_trips.reduce(0){|s,t| s + (t.ads_taxi_cost || 0)}
    @total_partner_cost   = all_trips.reduce(0){|s,t| s + (t.ads_partner_cost || 0)} + @run_groups.keys.reduce(0){|s,r| s + r.ads_partner_cost}
    @total_scheduling_fee = all_trips.reduce(0){|s,t| s + (t.ads_scheduling_fee || 0)} + @run_groups.keys.reduce(0){|s,r| s + r.ads_scheduling_fee}
    @total_cost           = all_trips.reduce(0){|s,t| s + (t.ads_total_cost || 0)} + @run_groups.keys.reduce(0){|s,r| s + r.ads_total_cost}
    @total_billable_hours = @run_groups.keys.reduce(0){|s,r| s + r.ads_billable_hours}
    @taxi_trip_count      = @trips_billed_per_trip.select{|t| t.bpa_provider?}.size
    @partner_trip_count   = @trips_billed_per_trip.reject{|t| t.bpa_provider?}.size

    if params[:output] == 'CSV'
      @filename = "#{@title} #{@query.start_date.strftime('%m-%d-%y')} - #{@query.end_date.strftime('%m-%d-%y')}.csv"
      render "premium_service_billing.csv" 
    end
  end

  def spd
    @query = ReportQuery.new(params[:report_query])
    trips = Trip.current_versions.completed.spd.date_range(@query.start_date,@query.after_end_date).includes(:customer).order("start_at DESC")

    @offices = {}
    @customer_rows = {}
    customer_office = {}
    @approved_rides = 0
    @customer_count = 0
    @all_billed_rides = @wc_billed_rides = @nonwc_billed_rides = @unknown_billed_rides = 0
    @all_mileage = @wc_mileage = @nonwc_mileage = @unknown_mileage = BigDecimal("0")

    for trip in trips
      row_key = trip.customer_id
      # Use the most recent case_manager_office a customer has for all trips
      customer_office[trip.customer_id] = trip.case_manager_office if customer_office[trip.customer_id].nil?
      office_key = (customer_office[trip.customer_id] || "Unspecified")
      @customer_rows[office_key] = {} unless @customer_rows.has_key?(office_key)
      unless @offices.has_key?(office_key)
        @offices[office_key] = {} 
        @offices[office_key][:approved_rides] = 0
        @offices[office_key][:billed_rides] = 0
        @offices[office_key][:billable_mileage] = BigDecimal.new("0")
        @offices[office_key][:customer_count] = 0
      end

      row = @customer_rows[office_key][row_key]
      if row.nil?
        @offices[office_key][:approved_rides] += trip.approved_rides || 0
        @offices[office_key][:customer_count] += 1
        @customer_count += 1
        @approved_rides += trip.approved_rides.to_i
        row = {:customer          => trip.customer,
               :billed_rides      => 0, 
               :billable_mileage  => BigDecimal.new("0"), 
               :mobility          => trip.wheelchair?,
               :date_enrolled     => trip.date_enrolled,
               :service_end       => trip.service_end,
               :approved_rides    => trip.approved_rides,
               :case_manager      => trip.case_manager}
        @customer_rows[office_key][row_key] = row
        row[:trips] = []
      end

      row[:billed_rides] += 1
      row[:billable_mileage] += trip.spd_mileage
      row[:mobility] = trip.wheelchair? if trip.wheelchair?
      row[:trips] << {:date => trip.date,
                      :estimated_mileage => trip.estimated_trip_distance_in_miles,
                      :billable_mileage => trip.spd_mileage,
                      :mobility => trip.wheelchair?}

      @offices[office_key][:billed_rides] += 1
      @offices[office_key][:billable_mileage] += trip.spd_mileage

      @all_billed_rides += 1
      @all_mileage += trip.spd_mileage
      if trip.wheelchair?.nil?
        @unknown_billed_rides += 1
        @unknown_mileage += trip.spd_mileage
      elsif trip.wheelchair?
        @wc_billed_rides += 1
        @wc_mileage += trip.spd_mileage
      else
        @nonwc_billed_rides += 1
        @nonwc_mileage += trip.spd_mileage
      end
    end
    if params[:output] == 'CSV'
      @filename = "SPD Report #{@query.start_date.strftime('%m-%d-%y')} - #{@query.end_date.strftime('%m-%d-%y')}.csv"
      render "spd.csv" 
    end
  end

  def ride_purpose
    @query = ReportQuery.new(params[:report_query])

    group_fields = ["county", "reporting_agency"]
    results = Allocation.group(group_fields, Allocation.where("reporting_agency_id IS NOT NULL"))
    @results = {}
    for county, rows in results
      @results[county] = {}
      for provider, allocations in rows
        row = @results[county][provider] = RidePurposeRow.new
        for allocation in allocations
          if allocation['trip_collection_method'] == 'trips'
            row.collect_by_trip(allocation, @query.start_date, @query.after_end_date)
          else
            row.collect_by_summary(allocation, @query.start_date, @query.after_end_date)
          end
        end
      end
    end
    @trip_purposes = RidePurposeRow.trip_purposes
  end

  def quarterly_narrative
    @query = ReportQuery.new(params[:report_query])

    @report = FlexReport.new
    @report.start_date = @query.start_date
    @report.end_date = @query.after_end_date - 1.month
    @report.reporting_agency_list =  params[:report_query][:provider_id] if params[:report_query].present? && params[:report_query][:provider_id].present?
    @report.field_list = 'admin_volunteer_hours,agency_other,cost_per_hour,cost_per_mile,cost_per_trip,donations,driver_paid_hours,driver_total_hours,driver_volunteer_hours,escort_volunteer_hours,funds,in_district_trips,mileage,miles_per_ride,out_of_district_trips,total,total_trips,total_volunteer_hours,turn_downs,undup_riders,vehicle_maint'
    @report.group_by = "reporting_agency,program,quarter,month"
    @report.populate_results!
  end

  def trimet_export
    @query = ReportQuery.new(params[:report_query])

    @report = FlexReport.new
    @report.start_date = @query.start_date
    @report.end_date = @query.start_date # One month only
    @report.elderly_and_disabled_only = true
    if params[:output] == 'Audit'
      @report.group_by = "provider_name,allocation_name"
      template_name = "trimet_export_audit.csv"
      @filename = "#{@report.start_date.strftime("%Y-%m")} Ride Connection E & D Performance Audit Report.csv"
    else
      @report.group_by = "trimet_provider_name,trimet_program_name,trimet_provider_identifier,trimet_program_identifier"
      @report.county_names = [:none] # This has the effect of making sure only the allocations below are used.
      @report.allocations = Allocation.in_trimet_report_group.active_in_range(@report.start_date,@query.after_end_date).map{|a| a.id }
      template_name = "trimet_export.csv"
      @filename = "#{@report.start_date.strftime("%Y-%m")} Ride Connection E & D Performance Report.csv"
    end
    @report.populate_results!

    render template_name
  end

  def age_and_ethnicity
    @query = ReportQuery.new(params[:report_query])
    #we need new riders this month, where new means "first time this fy"
    #so, for each trip this month, find the customer, then find out whether 
    # there was a previous trip for this customer this fy

    trip_customers = Trip.current_versions.select("DISTINCT customer_id").for_provider(@query.provider_id).completed
    prior_customers_in_fiscal_year = trip_customers.for_date_range(fiscal_year_start_date(@query.start_date), @query.start_date).map {|x| x.customer_id}
    customers_this_period = trip_customers.for_date_range(@query.start_date, @query.after_end_date).map {|x| x.customer_id}

    new_customers = Customer.where(:id => (customers_this_period - prior_customers_in_fiscal_year))
    earlier_customers = Customer.where(:id => prior_customers_in_fiscal_year)

    @this_month_unknown_age = 0
    @this_month_sixty_plus = 0
    @this_month_less_than_sixty = 0

    @this_year_unknown_age = 0
    @this_year_sixty_plus = 0
    @this_year_less_than_sixty = 0

    @counts_by_ethnicity = {}

    #first, handle the customers from this month
    for customer in new_customers
      age = customer.age_in_years(fiscal_year_start_date(@query.start_date))
      if age.nil?
        @this_month_unknown_age += 1
        @this_year_unknown_age += 1
      elsif age > 60
        @this_month_sixty_plus += 1
        @this_year_sixty_plus += 1
      else
        @this_month_less_than_sixty += 1
        @this_year_less_than_sixty += 1
      end
      
      ethnicity = customer.race || "Unspecified"
      if ! @counts_by_ethnicity.member? ethnicity
        @counts_by_ethnicity[ethnicity] = {'month' => 0, 'year' => 0}
      end
      @counts_by_ethnicity[ethnicity]['month'] += 1
      @counts_by_ethnicity[ethnicity]['year'] += 1
    end

    #now the customers who appear earlier in the year 
    for customer in earlier_customers
      age = customer.age_in_years(fiscal_year_start_date(@query.start_date))
      if age.nil?
        @this_year_unknown_age += 1
      elsif age > 60
        @this_year_sixty_plus += 1
      else
        @this_year_less_than_sixty += 1
      end

      ethnicity = customer.race || "Unspecified"
      if ! @counts_by_ethnicity.member? ethnicity
        @counts_by_ethnicity[ethnicity] = {'month' => 0, 'year' => 0}
      end
      @counts_by_ethnicity[ethnicity]['year'] += 1
    end

  end
  
  private

  def fiscal_year_start_date(date)
    year = (date.month < 7 ? date.year - 1 : date.year)
    Date.new(year, 7, 1)
  end

end
