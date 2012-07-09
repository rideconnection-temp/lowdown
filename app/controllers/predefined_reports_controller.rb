class ReportQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date, :end_date, :after_end_date, :provider_id, :provider

  def initialize(params = {})
    params = {} if params.nil?
    now = Date.today
    if params[:start_date]
      @start_date = params[:start_date].to_date
    elsif params[:date_range] == :quarter
      @start_date = Date.new(Date.today.year, (Date.today.month-1)/3*3+1,1) - 3.months
    else
      @start_date = Date.new(now.year, now.month, 1).prev_month
    end

    if params[:end_date]
      @end_date = params[:end_date].to_date
      @after_end_date = @end_date + 1.day
    elsif params[:date_range] == :quarter
      @after_end_date = start_date + 3.months
      @end_date = @after_end_date - 1.day
    else
      @after_end_date = start_date.next_month
      @end_date = @after_end_date - 1.day
    end

    if params[:provider]
      @provider = params[:provider]
    end

    if params[:provider_id]
      @provider_id = params[:provider_id].to_i
    end
  end

  def persisted?
    false
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
  end

  def multnomah_ads
    @query = ReportQuery.new(params[:report_query])
    trips = Trip.current_versions.completed.date_range(@query.start_date,@query.after_end_date).includes(:customer,{:allocation => :provider},:pickup_address,:dropoff_address).default_order
    trips_billed_per_hour = trips.multnomah_ads_billed_per_hour
    @trips_billed_per_trip = trips.multnomah_ads_billed_per_trip
    @run_groups = trips_billed_per_hour.group_by(&:run)
    all_trips = trips_billed_per_hour + @trips_billed_per_trip
    @total_taxi_cost      = all_trips.reduce(0){|s,t| s + (t.ads_taxi_cost || 0)}
    @total_partner_cost   = all_trips.reduce(0){|s,t| s + (t.ads_partner_cost || 0)} + @run_groups.keys.reduce(0){|s,r| s + r.ads_partner_cost}
    @total_scheduling_fee = all_trips.reduce(0){|s,t| s + (t.ads_scheduling_fee || 0)} + @run_groups.keys.reduce(0){|s,r| s + r.ads_scheduling_fee}
    @total_cost           = all_trips.reduce(0){|s,t| s + (t.ads_total_cost || 0)} + @run_groups.keys.reduce(0){|s,r| s + r.ads_total_cost}
    @total_billable_hours = @run_groups.keys.reduce(0){|s,r| s + r.ads_billable_hours}
    @per_hour_trip_count  = trips_billed_per_hour.size
    @taxi_trip_count      = @trips_billed_per_trip.select{|t| t.bpa_provider?}.size
    @partner_trip_count   = @trips_billed_per_trip.reject{|t| t.bpa_provider?}.size

    render_csv "Multnomah County ADS Report", "multnomah_ads.csv" if params[:output] == 'CSV'
  end

  def spd
    @query = ReportQuery.new(params[:report_query])
    trips = Trip.current_versions.completed.spd.date_range(@query.start_date,@query.after_end_date).includes(:customer)

    @spd_offices = {}
    @customer_rows = {}
    @approved_rides = 0
    @wc_billed_rides = @nonwc_billed_rides = @unknown_billed_rides = 0
    @wc_mileage = @nonwc_mileage = @unknown_mileage = 0

    for trip in trips
      row_key = [trip.customer_id, trip.wheelchair?]
      customer = trip.customer
      office_key = trip.case_manager_office
      @customer_rows[office_key] = {} unless @customer_rows.has_key?(office_key)

      row = @customer_rows[office_key][row_key]
      if row.nil?
        row = {:customer          => customer,
               :billed_rides      => 0, 
               :billable_mileage  => 0, 
               :mobility          => trip.wheelchair?,
               :date_enrolled     => trip.date_enrolled,
               :service_end       => trip.service_end,
               :approved_rides    => trip.approved_rides,
               :case_manager      => trip.case_manager}
        @customer_rows[office_key][row_key] = row
      end

      row[:billed_rides] += 1
      row[:billable_mileage] += trip.spd_mileage

      @approved_rides += trip.approved_rides.to_i
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
  end

  def ride_purpose
    @query = ReportQuery.new(params[:report_query])

    results = Allocation.all
    group_fields = ["county", "provider"]
    allocations = group(group_fields, results)
    @counties = {}
    for county, rows in allocations
      @counties[county] = {}
      for provider, allocations in rows
        row = @counties[county][provider] = RidePurposeRow.new
        for allocation in allocations
          if allocation['trip_collection_method'] == 'trips'
            row.collect_by_trip(allocation, @query.start_date, @query.end_date)
          else
            row.collect_by_summary(allocation, @query.start_date, @query.end_date)
          end

        end
      end
    end
    @trip_purposes = RidePurposeRow.trip_purposes
  end

  def quarterly_narrative
    @report = FlexReport.new
    @report.start_date = date_from_params(params[:report_query],"start_date")
    @report.end_date = date_from_params(params[:report_query],"end_date")
    @report.provider_list =  params[:report_query][:provider_id] if params[:report_query][:provider_id].present?
    @report.group_by = "allocation_name,month"
    @report.populate_results!
  end

  def age_and_ethnicity
    @query = ReportQuery.new(params[:report_query])

    allocations = Allocation.joins(:provider).
        where("providers.name=? and exists(SELECT id FROM trips WHERE trips.allocation_id=allocations.id)", @query.provider)

    if allocations.empty?
      flash[:notice] = "No allocations for this provider"
      return redirect_to :action => :index
    end

    allocation_ids = allocations.map { |x| x.id }

    undup_riders_sql = "select count(*) as undup_riders, %s from (select customer_id, fiscal_year(date) as year, min(fiscal_month(date)) as month from trips inner join customers on trips.customer_id=customers.id where allocation_id in (?) and valid_end=? and result_code = 'COMP' group by customer_id, year) as customer_ids, customers where year = ? %%s and customers.id=customer_id group by %s"

    #unduplicated by age this month
    undup_riders_age_sql = undup_riders_sql % ["age(customers.birthdate) > interval '60 years' as over60", "over60"]
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_age_sql % "and month = ?", 
                                                          allocation_ids, Trip.end_of_time, 
                                                          @query.start_date.advance(:months=>6).year, 
                                                          @query.start_date.advance(:months=>6).month]))

    @current_month_unduplicated_old = @current_month_unduplicated_young = @current_month_unduplicated_unknown = 0
    for row in rows
      if row['over60'] == 't'
        @current_month_unduplicated_old = row['undup_riders'].to_i
      elsif row['over60'] == 'f'
        @current_month_unduplicated_young = row['undup_riders'].to_i
      else
        @current_month_unduplicated_unknown = row['undup_riders'].to_i
      end
    end

    #unduplicated by age ytd
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_age_sql % "",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @query.start_date.advance(:months=>6).year]))

    @ytd_age_old = @ytd_age_young = @ytd_age_unknown = 0
    for row in rows
      if row['over60'] == 't'
        @ytd_age_old = row['undup_riders'].to_i
      elsif row['over60'] == 'f'
        @ytd_age_young = row['undup_riders'].to_i
      else
        @ytd_age_unknown = row['undup_riders'].to_i
      end
    end

    #now, by ethnicity
    undup_riders_ethnicity_sql = undup_riders_sql % ["race", "race"]
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_ethnicity_sql % "and month = ?",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @query.start_date.advance(:months=>6).year, 
                                                          @query.start_date.advance(:months=>6).month]))

    @ethnicity = {}
    for row in rows
      @ethnicity[row["race"] || 'Unknown'] = {"unduplicated" => row['undup_riders']}
    end

    #ethnicity ytd
    rows = ActiveRecord::Base.connection.select_all(bind([undup_riders_ethnicity_sql % "",
                                                          allocation_ids, Trip.end_of_time, 
                                                          @query.start_date.advance(:months=>6).year]))

    for row in rows
      race = row["race"] || 'Unknown'
      if ! @ethnicity.member? race
        @ethnicity[race] = {"unduplicated" => 0}
      end
      @ethnicity[race]["ytd"] = row['undup_riders']
    end
  end

  private

  def date_from_params(params_in,attribute_name)
    Date.new( params_in["#{attribute_name}(1i)"].to_i, params_in["#{attribute_name}(2i)"].to_i, params_in["#{attribute_name}(3i)"].to_i ) 
  end
  
end
