class ReportQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date, :end_date, :end_month, :after_end_date, :provider_id, :reporting_agency_id, :provider, :county, :group_by

  def initialize(params = {})
    params = {} if params.nil?
    now = Date.today
    if params[:start_date]
      @start_date = params[:start_date].to_date
    elsif params['start_date(1i)']
      @start_date = date_from_params(params,:start_date)
    elsif params[:date_range] == :semimonth
      if now.day < 16
        @start_date = Date.new((now - 1.month).year, (now - 1.month).month, 16)
      else
        @start_date = Date.new(now.year, now.month, 1)
      end
    elsif params[:date_range] == :quarter
      @start_date = Date.new(now.year, (now.month-1)/3*3+1,1) - 3.months
    elsif params[:date_range] == :fiscal_year_to_date
      if (now - 1.month).month > 6
        @start_date = Date.new((now - 1.month).year, 7, 1)
      else
        @start_date = Date.new((now - 1.month).year - 1, 7, 1)
      end
    else
      @start_date = Date.new(now.year, now.month, 1).prev_month
    end

    if params[:end_date]
      @after_end_date = params[:end_date].to_date + 1.day
    elsif params['end_month(1i)']
      d = date_from_params(params,:end_month)
      @after_end_date = Date.new(d.year,d.month,1) + 1.month
    elsif params['end_date(1i)']
      @after_end_date = date_from_params(params,:end_date) + 1.month
    elsif params[:date_range] == :semimonth
      if now.day < 16
        @after_end_date = Date.new(now.year, now.month, 1)
      else
        @after_end_date = Date.new(now.year, now.month, 16)
      end
    elsif params[:date_range] == :quarter
      @after_end_date = @start_date + 3.months
    elsif params[:date_range] == :fiscal_year_to_date
      @after_end_date = Date.new(now.year,now.month,1)
    else
      @after_end_date = @start_date + 1.month
    end
    @end_date = @after_end_date - 1.day
    @end_month = Date.new(@end_date.year,@end_date.month,1)

    @provider = params[:provider]                            if params[:provider].present?
    @provider_id = params[:provider_id].to_i                 if params[:provider_id].present?
    @county = params[:county]                                if params[:county].present?
    @reporting_agency_id = params[:reporting_agency_id].to_i if params[:reporting_agency_id].present?
    @group_by = params[:group_by]                            if params[:group_by].present?
  end

  def persisted?
    false
  end

  private

  def date_from_params(params_in,attribute_name)
    Date.new( params_in["#{attribute_name}(1i)"].to_i, params_in["#{attribute_name}(2i)"].to_i, params_in["#{attribute_name}(3i)"].to_i ) 
  end
end

class PredefinedReportsController < ApplicationController
  require 'csv'

  def index
    @query = ReportQuery.new
    @quarterly_query = ReportQuery.new(:date_range => :quarter)
    @fiscal_year_to_date_query = ReportQuery.new(:date_range => :fiscal_year_to_date)
    @semimonth_query = ReportQuery.new(:date_range => :semimonth)
    @selected_groupings = ["funding_source","funding_subsource","project_number","project_name","program_name","reporting_agency_name"]
  end

  def premium_service_billing
    @query = ReportQuery.new(params[:report_query])
    trips = Trip.current_versions.completed.date_range(@query.start_date,@query.after_end_date).
            includes(:customer,{:allocation => :provider},:pickup_address,:dropoff_address,:run).default_order
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
    trips_billed_per_hour           = trips.billed_per_hour
    @trips_billed_per_trip          = trips.billed_per_trip
    all_trips                       = trips_billed_per_hour + @trips_billed_per_trip
    @run_groups                     = Allocation.group(%w{run}, trips_billed_per_hour)
    @grouped_trips_billed_per_hour  = Allocation.group(%w{provider run}, trips_billed_per_hour )

    @total_taxi_cost                = all_trips.reduce(0){|s,t| s + (t.ads_taxi_cost || 0)}
    @total_partner_cost             = all_trips.reduce(0){|s,t| s + (t.ads_partner_cost || 0)} + 
                                      @run_groups.keys.reduce(0){|s,r| s + r.ads_partner_cost}
    @total_scheduling_fee           = all_trips.reduce(0){|s,t| s + (t.ads_scheduling_fee || 0)} + 
                                      @run_groups.keys.reduce(0){|s,r| s + r.ads_scheduling_fee}
    @total_cost                     = all_trips.reduce(0){|s,t| s + (t.ads_total_cost || 0)} + 
                                      @run_groups.keys.reduce(0){|s,r| s + r.ads_total_cost}
    @total_billable_hours           = @run_groups.keys.reduce(0){|s,r| s + r.ads_billable_hours}
    @taxi_trips                     = @trips_billed_per_trip.select{|t| t.bpa_provider?}
    @grouped_taxi_trips             = Allocation.group(['provider'],@taxi_trips)
    @partner_trips                  = @trips_billed_per_trip.reject{|t| t.bpa_provider?}
    @grouped_partner_trips          = Allocation.group(['provider'],@partner_trips)

    if params[:output] == 'CSV'
      @filename = "#{@title} #{@query.start_date.to_s(:mdy)} - #{@query.end_date.to_s(:mdy)}.csv"
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
      @filename = "SPD Report #{@query.start_date.to_s(:mdy)} - #{@query.end_date.to_s(:mdy)}.csv"
      render "spd.csv" 
    end
  end

  def trip_purpose
    @query = ReportQuery.new(params[:report_query])

    group_fields = ["county", "reporting_agency"]
    a = Allocation.active_in_range(@query.start_date,@query.after_end_date).
                   where("reporting_agency_id IS NOT NULL AND admin_ops_data <> 'Required'")
    a = a.where(:reporting_agency_id => @query.reporting_agency_id) if @query.reporting_agency_id.present?
    grouped_allocations = Allocation.group(group_fields, a)

    @results = {}
    for county, rows in grouped_allocations
      @results[county] = {}
      for provider, allocations in rows
        row = @results[county][provider] = TripPurposeRow.new
        for allocation in allocations
          if allocation['trip_collection_method'] == 'trips'
            row.collect_by_trip(allocation, @query.start_date, @query.after_end_date)
          else
            row.collect_by_summary(allocation, @query.start_date, @query.after_end_date)
          end
        end
      end
    end
    @trip_purposes = TripPurposeRow.trip_purposes
    if params[:output] == 'CSV'
      @filename = "Trip Purpose Report #{@query.start_date.to_s(:mdy)} - #{@query.end_date.to_s(:mdy)}.csv"
      render "trip_purpose.csv" 
    end
  end

  def quarterly_narrative
    @query = ReportQuery.new(params[:report_query])

    @report = FlexReport.new
    @report.start_date = @query.start_date
    @report.end_date = @query.end_date
    @report.reporting_agency_list = @query.provider_id.to_s if @query.provider_id.present?
    @report.fields = [
      :admin_volunteer_hours,
      :agency_other,
      :cost_per_hour,
      :cost_per_mile,
      :cost_per_trip,
      :donations,
      :driver_paid_hours,
      :driver_total_hours,
      :driver_volunteer_hours,
      :escort_volunteer_hours,
      :funds,
      :in_district_trips,
      :mileage,
      :miles_per_ride,
      :out_of_district_trips,
      :total,
      :total_trips,
      :total_volunteer_hours,
      :turn_downs,
      :undup_riders,
      :vehicle_maint
    ].map(&:to_s)
    @report.group_by = "reporting_agency,program,county,quarter,month"
    @report.populate_results!

    @summary_report = FlexReport.new
    @summary_report.report_rows = @report.report_rows
    @summary_report.group_by = "reporting_agency,quarter,month"
    @summary_report.group_report_rows!
  end

  def trimet_export
    @query = ReportQuery.new(params[:report_query])

    @report = FlexReport.new
    @report.start_date = @query.start_date
    @report.end_month = @query.start_date # One month only
    @report.fields = [
      :total_elderly_and_disabled_trips,
      :mileage,
      :total_elderly_and_disabled_cost,
      :undup_riders
    ].map(&:to_s)
    @report.elderly_and_disabled_only = true
    if params[:output] == 'Audit'
      @report.group_by = "provider_name,allocation_name"
      template_name = "trimet_export_audit.csv"
      allocation_instance = Allocation.not_vehicle_maintenance_only
      @filename = "#{@report.start_date.to_s(:ym)} Ride Connection E & D Performance Audit Report.csv"
    else
      @report.group_by = "trimet_provider_name,trimet_program_name,trimet_provider_identifier,trimet_program_identifier"
      template_name = "trimet_export.csv"
      allocation_instance = Allocation.has_trimet_provider
      @filename = "#{@report.start_date.to_s(:ym)} Ride Connection E & D Performance Report.csv"
    end
    @report.populate_results!(allocation_instance)

    render template_name
  end

  def age_and_ethnicity
    @query = ReportQuery.new(params[:report_query])
    # We need new riders this month, where new means "first time this fy"
    # so, for each trip this month, find the customer, then find out whether 
    # there was a previous trip for this customer this fy

    trip_customers = Trip.current_versions.select("DISTINCT customer_id").completed
    trip_customers = trip_customers.for_provider(@query.provider_id) if @query.provider_id.present?
    trip_customers = trip_customers.for_reporting_agency(@query.reporting_agency_id) if @query.reporting_agency_id.present?
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

  def bpa_invoice
    @query = ReportQuery.new(params[:report_query])
    @report = FlexReport.new
    @report.start_date  = @query.start_date
    @report.end_date    = @query.end_date
    @report.group_by    = "project_number_and_name,override_name"
    @report.field_list  = 'funds,total_trips,mileage,driver_total_hours,cost_per_trip'
    @report.providers   = [@query.provider_id]
    if params[:output] == 'Summary'
      @report.populate_results!
    elsif params[:output] == 'Details'
      @report.collect_allocation_objects! 
      a_ids = @report.allocation_objects.map{|a| a.id }
      @trips = Trip.current_versions.completed.for_allocation_id(a_ids).
        for_date_range(@query.start_date,@query.after_end_date).
        joins(:customer).includes(:customer, :allocation => [:project, :override]).
        order("trips.start_at, customers.last_name")
      @total_customers_served =     @trips.inject(0){|sum, t| sum + t.customers_served }
      @total_apportioned_duration = @trips.inject(0){|sum, t| sum + t.apportioned_duration }
      @total_apportioned_mileage =  @trips.inject(0){|sum, t| sum + t.apportioned_mileage }
      @total_apportioned_fare =     @trips.inject(0){|sum, t| sum + t.apportioned_fare }
      render "bpa_invoice_details.html"
    end
  end
  
  def allocation_summary
    @query = ReportQuery.new(params[:report_query])
    group_by = @query.group_by.split(",")
    @groupings = group_by.map{|x| [x, FlexReport::GroupMappings[x]] }
    allocations = Allocation.active_on(Date.today).includes(:program, :reporting_agency, :provider, :project => [:funding_source])
    all_nodes = Allocation.group(@groupings.map{|x| x[0] }, allocations)
    @flattened_nodes = flatten_nodes([], all_nodes, 0)
  end
  
  private

  def flatten_nodes(node_list, node_in, level)
    if node_in.is_a?(Hash) 
      node_in.sort_by {|k,v| row_sort(k)}.each do |this_key, this_value|
        this_node = {}
        this_node[:level] = level
        this_node[:allocation] = Allocation.member_allocation(this_value)
        this_node[:member_count] = Allocation.count_members(this_value, @groupings.size - level - 1)
        node_list << this_node
        flatten_nodes node_list, this_value, level + 1 
      end
      node_list
    end
  end

  def row_sort(k)
    if k.blank?
      [2, ""]
    elsif k.class == Fixnum
      [1, ("%04d" % k)]
    else
      [1, k.to_s.downcase]
    end
  end

  def fiscal_year_start_date(date)
    year = (date.month < 7 ? date.year - 1 : date.year)
    Date.new(year, 7, 1)
  end

end
