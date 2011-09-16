require 'csv'

class TripQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date, :end_date, :provider, :allocation, :dest_allocation, :commit

  def initialize(params, commit = nil)
    params ||= {}

    @commit          = commit
    @end_date        = params["end_date"] ? Date.parse(params["end_date"]) : Date.today
    @start_date      = params["start_date"] ? Date.parse(params["start_date"]) : @end_date - 5
    @provider        = params[:provider]          
    @allocation      = params[:allocation]
    @dest_allocation = params[:dest_allocation]
  end

  def persisted?
    false
  end

  def conditions
    d = {}
    d[:date]                     = start_date..end_date if start_date
    d["allocations.provider_id"] = provider if provider.present?
    d[:allocation_id]            = allocation if allocation.present?
    d
  end
  
  def update_allocation?
    @commit.try(:downcase) == "transfer trips" && @dest_allocation.present? && @dest_allocation != @allocation
  end

  def csv?
    @commit.present? && @commit.downcase.include?( "csv" )
  end
end

class TripsController < ApplicationController
  before_filter :require_admin_user, :only=>[:import]

  def index
    redirect_to :action=>:list
  end

  def list
    @query       = TripQuery.new params[:trip_query], params[:commit]
    @providers   = Provider.find :all
    @allocations = Allocation.find :all

    @trips = Trip.current_versions.find(:all, :include=>[:pickup_address, :dropoff_address, :run, :customer, :allocation], :conditions=>@query.conditions)

    if @query.csv?
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

        for trip in @trips
          csv << good_columns.map {|x| trip.send(x)} + [trip.customer.name, trip.allocation.name, trip.run.name] + address_fields(trip.home_address) + address_fields(trip.pickup_address) + address_fields(trip.dropoff_address)
        end
      end
      return send_data csv, :type => "text/plain", :filename => "trips.csv", :disposition => 'attachment'

    else
      @trips = @trips.paginate :page => params[:page], :per_page => 30, :conditions => @query.conditions, :joins=>:allocation
      
    end
  end
  
  def update_allocation
    @query       = TripQuery.new params[:trip_query], params[:commit]
    @allocations = Allocation.all
    
    if @query.update_allocation?
      @transfer_count = params[:transfer_count] || 0

      # postgres doesn't support update & limit, we can't use limit option of update_all
      trips    = Trip.current_versions.where( @query.conditions ).limit(@transfer_count)
      
      if trips.present?
        now      = trips.first.now_rounded
        trip_ids = trips.map &:id      
      
        @transfer_count = Trip.update_all ["allocation_id = ?, updated_at = ?, updated_by = ?, valid_start = ?", @query.dest_allocation, Time.now, current_user.id, now], ["id in (?)", trip_ids]
      
        for trip in trips
          trip.create_revision_with_known_attributes_without_callbacks :allocation_id => @query.allocation
        end
      end
      
      @allocation = Allocation.find @query.dest_allocation
    end
    
    @trips_count = Trip.current_versions.where( @query.conditions ).count
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
  end

  def import
    if ! params['file-import']
      redirect_to :action=>:show_import and return
    end
    file = params['file-import'].tempfile
    processed = TripImport.new(:file_path=>file)
    if processed.save
      flash[:notice] = "Import complete - #{processed.record_count} records processed.</div>"
      render 'show_import'
    else
#     TODO: make into a flash error
      flash[:notice] = "Import aborted due to the following error(s):<br/>#{processed.problems}"
      render 'show_import'
    end
  end

  def show
    @trip = Trip.find(params[:id])
    @customer = @trip.customer
    @home_address = @trip.home_address
    @pickup_address = @trip.pickup_address
    @dropoff_address = @trip.dropoff_address
    @updated_by_user = @trip.updated_by_user
    @allocations = Allocation.find(:all)
  end
  
  def update
    old_trip = Trip.find(params[:trip][:id])
    @trip = old_trip.current_version
    # clean_new_row # needed for Trips?
    @trip.update_attributes(params[:trip]) ?
      redirect_to(:action=>:show, :id=>@trip) : render(:action => :show)
  end

  def show_bulk_update

  end

  def bulk_update

   start_date = Date.parse(params[:start_date])
   end_date = Date.parse(params[:end_date])

   updated = Run.current_versions.where("date >= ? and date <= ?", start_date, end_date).count

   Run.current_versions.update_all({ :complete=>true }, ["date >= ? and date <= ?", start_date, end_date])

   flash[:notice] = "Updated #{updated} records"
   redirect_to :action=>:show_bulk_update
  end

  private

  def address_fields(address)
    [address.common_name, address.building_name, address.address_1, address.address_2, address.city, address.state, address.postal_code]
  end
end
