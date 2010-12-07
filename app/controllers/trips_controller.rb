class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date
  attr_accessor :end_date

  attr_accessor :provider
  attr_accessor :allocation

  def persisted?
    false
  end

  def conditions
    d = {}
    if start_date
      d[:date] = start_date..end_date
    end
    if provider
      d[:provider] = provider
    end
    if allocation
      d[:allocation] = allocation
    end
    d
  end
end

class TripsController < ApplicationController

  def index
  end

  def list
    @query = Query.new(params[:query])
    if !@query.conditions
      @query.end_date = Time.now
      @query.start_date = @query.end_date - 5 * 24 * 60 * 60
      flash[:notice] = 'No search criteria set - showing default (past 5 days)'
    end

    @providers = Provider.find :all
    @allocations = Allocation.find :all


    @trips = Trip.paginate :page => params[:page], :per_page => 30, :conditions => @query.conditions
  end

  def show_import
  end

  def import
    file = params['file-import'].tempfile
    processed = TripImport.import_file(file)

    flash[:notice] = "Import complete - #{processed} records processed.</div>"
    render 'show_import'
  end

  def view
  end


end
