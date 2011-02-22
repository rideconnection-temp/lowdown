class SummariesController < ApplicationController
  before_filter :require_user
  before_filter :require_admin_user, :except=>[:index]

  def index
    @summaries = Summary.current_versions.all
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
    if !flash[:notice] 
      flash[:notice] = "This will mark all summaries within the selected range as complete. There is no 'undo'."
    end
  end

  def bulk_update
    updated = 0

    start_day = params[:update]['start_date(1i)'].to_i
    start_month = params[:update]['start_date(2i)'].to_i
    start_year = params[:update]['start_date(3i)'].to_i
    start_date = Date.new(start_day, start_month, start_year)

    end_day = params[:update]['end_date(1i)'].to_i
    end_month = params[:update]['end_date(2i)'].to_i
    end_year = params[:update]['end_date(3i)'].to_i
    end_date = Date.new(end_day, end_month, end_year)

    for summary in Summary.current_versions.where("period_start >= ? and period_end < ?", start_date, end_date)
      updated += 1
      summary.complete = true
      summary.save!
    end
    flash[:notice] = "Updated #{updated} records"
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
