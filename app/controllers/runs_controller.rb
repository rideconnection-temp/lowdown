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
      if params["start_date"]
        @start_date = Date.parse(params["start_date"])
      end
      if params["end_date"]
        @end_date = Date.parse(params["end_date"])
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

class RunsController < ApplicationController
  before_filter :require_admin_user, :except=>[:index, :show]
  
  def index
    @query = Query.new(params[:query])
    if @query.conditions.empty?
      @query.end_date = Date.today
      @query.start_date = @query.end_date - 30
      flash[:notice] = 'No search criteria set - showing default (most recent 30 days)'
    else
      flash[:notice] = nil
    end

    @runs = Run.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => @query.conditions

  end
  
  def create
    @run = Run.new(params[:run])
  end

  def show
    @run = Run.find(params[:id])
  end

  def update
    @run = Run.current_versions.find(params[:run][:id])
    @run.update_attributes(params[:run]) ?
      redirect_to(:action=>:show, :id=>@run) : render(:action => :show)
  end

  def bulk_update
    updated = 0

    @query = Query.new(params[:query])
    if @query.conditions.empty?
      flash[:alert] = "Cannot update without date range"
    else
      for run in Run.current_versions :conditions => @query.conditions
        updated += 1
        run.complete = true
        run.save!
      end
      flash[:notice] = "Updated #{updated} records"

    end
    redirect_to :action=>:index
  end

end
