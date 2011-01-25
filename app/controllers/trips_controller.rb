class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date
  attr_accessor :end_date

  attr_accessor :provider
  attr_accessor :allocation

  def convert_date(obj, base)
    return Date.new(obj["#{base}(1i)"].to_i,obj["#{base}(2i)"].to_i,obj["#{base}(3i)"].to_i)
  end

  def initialize(params)
    if params
      if params["start_date(1i)"]
        @start_date = convert_date(params, :start_date)
      end
      if params["end_date(1i)"]
        @end_date = convert_date(params, :end_date)
      end
      if params[:provider]
        @provider = params[:provider].to_i
      end
      if params[:allocation]
        @allocation = params[:allocation].to_i
      end
    end
  end

  def persisted?
    false
  end

  def conditions
    d = {}
    if start_date
      d[:date] = start_date..end_date
    end
    if provider && provider != 0
      d["allocations.provider_id"] = provider
    end
    if allocation && allocation != 0
      d[:allocation_id] = allocation
    end
    d
  end
end

class TripsController < ApplicationController

  before_filter :require_user, :except=>[:import]
  before_filter :require_admin_user, :only=>[:import]

  def index
    redirect_to :action=>:list
  end

  def list
    @query = Query.new(params[:query])
    if @query.conditions.empty?
      @query.end_date = Time.now
      @query.start_date = @query.end_date - 5 * 24 * 60 * 60
      flash[:notice] = 'No search criteria set - showing default (past 5 days)'
    end

    @providers = Provider.find :all
    @allocations = Allocation.find :all


    @trips = Trip.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => @query.conditions, :joins=>:allocation
  end

  def share
    @trips = Trip.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => {:routematch_share_id=>params[:id]}
  end

  def run
    id = params[:id]
    @trips = Trip.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => {:run_id=>id}
    @run = Run.find(id)
  end

  def show_import
  end

  def import
    if ! params['file-import']
      redirect_to :action=>:show_import and return
    end
    file = params['file-import'].tempfile
    processed = TripImport.new(:file_path=>file)
    processed.save

    flash[:notice] = "Import complete - #{processed.record_count} records processed.</div>"
    render 'show_import'
  end

  def view
  end


end
