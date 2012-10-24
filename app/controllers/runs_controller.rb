class RunQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date, :end_date, :after_end_date, :provider, :allocation_id

  def initialize(params)
    params ||= {}
    @start_date = Date.parse(params["start_date"]) if params["start_date"].present?
    @end_date = Date.parse(params["end_date"]) if params["end_date"].present?
    @provider = params[:provider].to_i if params[:provider]
    @allocation_id = params[:allocation].to_i if params[:allocation]

    if @start_date.blank? || @end_date.blank?
      @start_date   = Date.today - 1.month - Date.today.day + 1.day
      @end_date     = @start_date + 1.month - 1.day
    end
    @after_end_date = @end_date + 1.day
  end

  def persisted?
    false
  end

  def apply_conditions(runs)
    runs = runs.for_date_range(start_date, after_end_date)
    runs = runs.for_provider(provider) if provider.present?
    runs = runs.for_allocation_id(allocation_id) if allocation_id.present?
    runs
  end
end

class RunsController < ApplicationController
  before_filter :require_admin_user, :except=>[:index, :show]
  
  def index
    @query = RunQuery.new(params[:run_query])
    @runs  = @query.apply_conditions(Run).current_versions.paginate :page => params[:page], :per_page => 30
  end
  
  def create
    @run = Run.new(params[:run])
  end

  def show
    @run = Run.find(params[:id])
    @trips = @run.trips.current_versions.paginate :page => params[:page], :per_page => 30
  end

  def update
    @run = Run.find(params[:run][:id]).current_version
    @run.attributes = params[:run]
    if has_real_changes? @run
      @run.update_attributes(params[:run]) ? redirect_to(:action=>:show, :id=>@run) : render(:action => :show)
    else
      redirect_to(:action=>:show, :id=>@run)
    end
  end
end
