require 'csv'

class TripQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :all_dates, :start_date, :end_date, :after_end_date, :provider, :subcontractor, 
      :allocation, :customer_first_name, :customer_last_name, :dest_allocation, :commit, :trip_import_id

  def initialize(params, commit = nil)
    params ||= {}
    @commit              = commit
    @trip_import_id      = params[:trip_import_id].present? ? params[:trip_import_id].to_i : nil
    @all_dates           = (params[:all_dates] == "1" || params[:all_dates] == true)
    @start_date          = Date.parse(params["start_date"]) if params["start_date"].present?
    @end_date            = Date.parse(params["end_date"]) if params["end_date"].present?
    if @start_date.blank? || @end_date.blank?
      if params['date_range'] == "semimonthly" 
        if Date.today.day > 15
          @start_date = Date.today - Date.today.day + 1.day
          @end_date   = @start_date + 14.days
        else
          @end_date   = Date.today - Date.today.day
          @start_date = @end_date - @end_date.day + 16.days
        end
      else
        @start_date   = Date.today - 1.month - Date.today.day + 1.day
        @end_date     = @start_date + 1.month - 1.day
      end
    end
    @after_end_date      = @end_date + 1.day
    @provider            = params[:provider].present? ? params[:provider].to_i : nil
    @subcontractor       = params[:subcontractor]
    @allocation          = params[:allocation].present? ? params[:allocation].to_i : nil
    @dest_allocation     = params[:dest_allocation].present? ? params[:dest_allocation].to_i : nil
    @customer_first_name = params[:customer_first_name]
    @customer_last_name  = params[:customer_last_name]
  end

  def persisted?
    false
  end

  def apply_conditions(trips)
    trips = trips.for_date_range(start_date,after_end_date) if !all_dates
    trips = trips.for_provider(provider) if provider.present?
    trips = trips.for_subcontractor(subcontractor) if subcontractor.present?
    trips = trips.for_allocation_id(allocation) if allocation.present?
    trips = trips.for_import(trip_import_id) if trip_import_id.present?
    trips = trips.for_customer_first_name_like(customer_first_name) if customer_first_name.present?
    trips = trips.for_customer_last_name_like(customer_last_name) if customer_last_name.present?
    trips
  end
  
  def update_allocation?
    @commit.try(:downcase) == "transfer trips" && @dest_allocation.present? && @dest_allocation != @allocation
  end

  def format
    return if @commit.blank?
    if @commit.downcase.include?("bpa")
      "bpa"
    elsif @commit.downcase.include?("csv")
      "general"
    end
  end
end

class TripsController < ApplicationController
  before_filter :require_admin_user, :only=>[:import]

  def index
    redirect_to :action=>:list
  end

  def list
    @query          = TripQuery.new params[:trip_query], params[:commit]
    @providers      = Provider.default_order
    @subcontractors = Provider.subcontractor_names
    @allocations    = Allocation.order(:name)

    @trips = Trip.current_versions.includes(:pickup_address, :dropoff_address, :run, :customer, :allocation => [:provider,:project]).joins(:allocation).order(:date,:trip_import_id)
    @trips = @query.apply_conditions(@trips)

    if @query.format == 'general'
      unused_columns = ["id", "base_id", "trip_import_id", "allocation_id", 
                        "home_address_id", "pickup_address_id", 
                        "dropoff_address_id", "customer_id", "run_id"] 

      good_columns = Trip.column_names.find_all {|x| ! unused_columns.member? x}

      csv = ""
      CSV.generate(csv) do |csv|
        csv << good_columns.map(&:titlecase) + %w{Customer Allocation Run
          Home\ Name Home\ Building Home\ Address\ 1 Home\ Address\ 2 Home\ City Home\ State Home\ Postal\ Code
          Pickup\ Name Pickup\ Building Pickup\ Address\ 1 Pickup\ Address\ 2 Pickup\ City Pickup\ State Pickup\ Postal\ Code
          Dropoff\ Name Dropoff\ Building Dropoff\ Address\ 1 Dropoff\ Address\ 2 Dropoff\ City Dropoff\ State Dropoff\ Postal\ Code}

        for trip in @trips.includes(:home_address)
          csv << good_columns.map {|x| trip.send(x)} + [trip.customer.name, trip.allocation.name, trip.run.try(:name)] + address_fields(trip.home_address) + address_fields(trip.pickup_address) + address_fields(trip.dropoff_address)
        end
      end
      return send_data csv, :type => "text/csv", :filename => "trips.csv", :disposition => 'attachment'
    elsif @query.format == 'bpa'
      @trips = @trips.completed
      render_csv "bpa_data", "bpa_index.csv"
    else
      @trips = @trips.paginate :page => params[:page], :per_page => 30
    end
  end
  
  def update_allocation
    @query       = TripQuery.new params[:trip_query], params[:commit]
    @providers   = Provider.order(:name).with_trip_data
    
    if @query.update_allocation?
      @completed_trips_count = @query.apply_conditions(Trip).current_versions.select("SUM(guest_count) AS g, SUM(attendant_count) AS a, COUNT(*) AS c").completed.first.attributes.values.inject(0) {|sum,x| sum + x.to_i }
      @completed_transfer_count = params[:transfer_count].try(:to_i) || 0
      @transfer_all = (params[:transfer_all] == '1' || params[:transfer_all] == true)
      if @completed_trips_count > 0 || @transfer_all 
        if @transfer_all
          ratio = 1
        else
          ratio = @completed_transfer_count/@completed_trips_count.to_f
        end
        
        @trips_transferred = {}
        now = Trip.new.now_rounded
        
        Trip.transaction do
          Trip::RESULT_CODES.values.each do |rc|
            if rc == 'COMP' && !@transfer_all
              this_transfer_count = @completed_transfer_count
            else
              this_transfer_count = ((@query.apply_conditions(Trip).select("COALESCE(SUM(guest_count),0) AS g, COALESCE(SUM(attendant_count),0) AS a, COUNT(*) AS c").current_versions.where(:result_code => rc).first.attributes.values.inject(0) {|sum,x| sum + x.to_i }) * ratio).to_i
            end

            trips_remaining = this_transfer_count
            @trips_transferred[rc] = 0
            # This is the maximum number of trips we'll need, if there are no guest or attendants. 
            # It may be fewer when guests & attendants are counted below
            trips = @query.apply_conditions(Trip).where(:result_code => rc).current_versions.limit(this_transfer_count)
            if trips.present?
              for trip in trips
                passengers = (trip.guest_count || 0) + (trip.attendant_count || 0) + 1
                if trips_remaining > 0 && passengers <= trips_remaining
                  trip.allocation_id = @query.dest_allocation 
                  trip.version_switchover_time = now
                  trip.save!
                  trips_remaining -= passengers
                  @trips_transferred[rc] += passengers
                end
              end
            end
          end
        end

        @allocation = Allocation.find @query.dest_allocation
      end
    end
    @trip_count = {}
    Trip::RESULT_CODES.values.each do |rc|
      @trip_count[rc] = @query.apply_conditions(Trip).select("SUM(guest_count) AS g, SUM(attendant_count) AS a, COUNT(*) AS c").current_versions.where(:result_code => rc).first.attributes.values.inject(0) {|sum,x| sum + x.to_i }
    end
  end

  def share
    @trips = Trip.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => {:routematch_share_id=>params[:id]}
  end

  def run
    id = params[:id]
    @trips = Trip.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => {:run_id=>id}
    @run = Run.find(id)
  end
  
  def import_trips
    id = params[:id]
    @trips = Trip.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => {:trip_import_id=>id}
    @import = TripImport.find(id)
  end

  def show_import
    @trip_imports = TripImport.order("trip_imports.created_at DESC").paginate :page => params[:page], :per_page => 30
  end

  def import
    if ! params['file-import']
      redirect_to :action=>:show_import and return
    end
    file = params['file-import'].tempfile
    processed = TripImport.new(:file_path=>file,:file_name => params['file-import'].original_filename)
    if processed.save
      flash[:notice] = "Import complete - #{processed.record_count} records processed.</div>"
      redirect_to :action => :show_import
    else
#     TODO: make into a flash error
      flash[:notice] = "Import aborted due to the following error(s):<br/>#{processed.problems}"
      redirect_to :action => :show_import
    end
  end

  def show
    @trip = Trip.find(params[:id])
    @customer = @trip.customer
    @home_address = @trip.home_address
    @pickup_address = @trip.pickup_address
    @dropoff_address = @trip.dropoff_address
    @updated_by_user = @trip.updated_by_user
    @allocations = Allocation.order(:name)
  end
  
  def update
    old_trip = Trip.find(params[:trip][:id])
    @trip = old_trip.current_version
    # clean_new_row # needed for Trips?
    @trip.update_attributes(params[:trip]) ?
      redirect_to(:action=>:show, :id=>@trip) : render(:action => :show)
  end

  def show_bulk_update
    params[:trip_query] = {} if params[:trip_query].blank?
    params[:trip_query][:date_range] = 'semimonthly'
    @query     = TripQuery.new params[:trip_query]
    @providers = [['Select a provider','']] + Provider.with_trip_data.default_order.map {|p| [p.to_s, p.id]}
    @incomplete_trips = {}
    Provider.with_trip_data.default_order.each do |p|
      trip_count = Trip.for_date_range(@query.start_date,@query.after_end_date).for_provider(p.id).data_entry_not_complete.count
      @incomplete_trips[p] = trip_count unless trip_count == 0
    end
  end

  def bulk_update
    @query = TripQuery.new params[:trip_query]
    unless @query.provider.blank?
      updated_runs = Run.current_versions.data_entry_not_complete.for_date_range(@query.start_date,@query.after_end_date).for_provider(@query.provider).update_all(:complete => true)
      updated_trips = Trip.current_versions.data_entry_not_complete.for_date_range(@query.start_date,@query.after_end_date).for_provider(@query.provider).update_all(:complete => true)
      flash[:notice] = "Updated #{updated_trips} trips records and #{updated_runs} run records"
    end
    redirect_to :action => :show_bulk_update, :trip_query => params[:trip_query]
  end

  private

  def address_fields(address)
    [address.common_name, address.building_name, address.address_1, address.address_2, address.city, address.state, address.postal_code]
  end

end
