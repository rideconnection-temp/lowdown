class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :period_start
  attr_accessor :period_end

  attr_accessor :allocation

  def initialize(params)
    if params
      if params[:period_start]
        @period_start = Date.parse(params[:period_start])
      end
      if params[:period_end]
        @period_end = Date.parse(params[:period_end])
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
    if @period_start
      d[:period_start] = @period_start..@period_end
      d[:period_end] = @period_start..@period_end
    end
    if allocation && allocation != 0
      d[:allocation_id] = allocation
    end
    d
  end
end

class SummariesController < ApplicationController
  before_filter :require_admin_user, :except=>[:index]

  def index
    @query = Query.new(params[:query])
    if @query.conditions.empty?
      @query.period_end = Date.today
      @query.period_start = @query.period_end.prev_month
      params[:query] = {:period_start => @query.period_start.to_s,
        :period_end => @query.period_end.to_s}
      flash.now[:notice] = 'No search criteria set - showing default (past month)'
    end

    @allocations = Allocation.find :all

    @summaries = Summary.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => @query.conditions, :joins=>:allocation

  end

  def show_create
    @summary = Summary.new
    
    POSSIBLE_TRIP_PURPOSES.each do |purpose|
      @summary.summary_rows.build(:purpose => purpose, :in_district_trips=>0, :out_of_district_trips=>0)
    end
    
    @allocations = Allocation.all
  end

  def create
    @summary = Summary.create(params[:summary])
    @summary.period_end = @summary.period_start.next_month
    @summary.save!
    if @summary
      redirect_to(:action=>:show_update, :id=>@summary.id)
    else
      @allocations = Allocation.all
      render(:action => :show_create)
    end
  end

  def show_bulk_update
    if !flash.now[:notice]
      flash.now[:notice] = "This will mark all summaries within the selected range as complete. There is no 'undo'."
    end
  end

  def bulk_update
    updated = 0

    @query = Query.new(params)
    if @query.conditions.empty?
      flash[:alert] = "Cannot update without date range"
    else
      for summary in Summary.current_versions.find(:all, :conditions=>@query.conditions)
        updated += 1
        summary.complete = true
        summary.save!
      end
      flash[:notice] = "Updated #{updated} records"

    end
    redirect_to :action=>:show_bulk_update
  end

  def show_update
    @summary = Summary.find params[:id]
    @allocations = Allocation.all
    @versions = @summary.versions.reverse
  end

  def update
    old_version = Summary.find(params[:summary][:id])
    @summary = old_version.current_version

    @allocations = Allocation.all

    @summary.update_attributes(params[:summary]) ?
      redirect_to(:action=>:show_update, :id=>@summary) : render(:action => :show_update)
    @summary.period_end = @summary.period_start.next_month
  end


end
