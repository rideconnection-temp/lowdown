class SummaryQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :period_start
  attr_accessor :period_end

  attr_accessor :provider

  def convert_date(obj, base)
    return Date.new(obj["#{base}(1i)"].to_i,obj["#{base}(2i)"].to_i,obj["#{base}(3i)"].to_i)
  end

  def initialize(params)
    if params
      if params["period_start(1i)"]
        @period_start = convert_date(params, "period_start")
      end
      if params["period_end(1i)"]
        @period_end = convert_date(params, "period_end")
      end
      if params[:period_start]
        @period_start = Date.parse(params[:period_start])
      end
      if params[:period_end]
        @period_end = Date.parse(params[:period_end])
      end
      if params[:provider]
        @provider = params[:provider].to_i
      end
    end
  end

  def persisted?
    false
  end

  def conditions
    arr = [""]
    if @period_start
      arr[0] = arr[0] << "period_start between ? and ? and period_end between ? and ?"
      arr += [@period_start, @period_end, @period_start, @period_end]
    end
    if provider && provider != 0
      arr[0] = arr[0] << "and allocation_id in (#{Allocation.where(:provider_id => provider).map(&:id).join(",")})"
    end
    arr
  end
end

class SummariesController < ApplicationController
  before_filter :require_admin_user, :except=>[:index]

  def index
    @query = SummaryQuery.new(params[:summary_query])
    if @query.conditions.first.empty?
      today = Date.today
      @query.period_end = Date.new(today.year, today.month, 1)
      @query.period_start = @query.period_end.prev_month
      params[:summary_query] = {:period_start => @query.period_start.to_s,
        :period_end => @query.period_end.to_s}
      flash.now[:notice] = 'No search criteria set - showing default (past month)'
    end

    @providers = Provider.order(:name).all
    @summaries = Summary.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => @query.conditions, :joins=>:allocation

  end

  def show_create
    @summary = Summary.new
    
    POSSIBLE_TRIP_PURPOSES.each do |purpose|
      @summary.summary_rows.build(:purpose => purpose, :in_district_trips=>0, :out_of_district_trips=>0)
    end
    
    @providers = Provider.order(:name).all
  end

  def create
    @summary = Summary.new(params[:summary])
    if ! @summary.summary_rows.size == POSSIBLE_TRIP_PURPOSES.size * 2
      flash.now[:alert] = "You must fill in all summary rows (even if just with zeros)"
      render(:action => :show_create)
    end
    if @summary.save
      redirect_to(:action=>:show_update, :id=>@summary.id)
    else
      @providers = Provider.order(:name).all
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

    @query = SummaryQuery.new(params[:summary_query])
    if @query.conditions.first.empty?
      flash[:alert] = "Cannot update without date range"
    else
      for summary in Summary.current_versions.find(:all, :conditions=>@query.conditions)
        next if summary.complete            
        updated += 1
        old_rows = summary.summary_rows.map &:clone
        summary.complete = true
        summary.save!
        prev = summary.previous
        for row in old_rows
          row.summary_id=prev.id
          row.save!
        end
      end
      flash[:notice] = "Updated #{updated} records"

    end
    redirect_to :action=>:show_bulk_update
  end

  def show_update
    @summary = Summary.find params[:id]
    @providers = Provider.order(:name).all
    @versions = @summary.versions.reverse
  end

  def update
    old_version = Summary.find(params[:summary][:id])
    @summary = old_version.current_version

    @providers = Provider.order(:name).all
    @versions = @summary.versions.reverse

    #gather up the old row objects
    old_rows = @summary.summary_rows.map &:clone

    @summary.attributes = params[:summary]
    if @summary.save
      #this created a new prior version, to which we want to reassign the
      #newly-created old-valued summary rows
      prev = @summary.previous
      for row in old_rows
        row.summary_id=prev.id
        row.save!
      end

      rows = @summary.summary_rows
      #and ensure that there are all rows for the current summary
      for purpose in POSSIBLE_TRIP_PURPOSES
        found = false
        for row in rows
          if row.purpose == purpose
            found = true
            break
          end
        end
        if not found
          SummaryRow.create(:summary_id=>@summary.id, :purpose=>purpose,:in_district_trips => 0, :out_of_district_trips=>0)
        end
      end
      redirect_to(:action=>:show_update, :id=>@summary)
    else
      render(:action => :show_update)
    end

  end


end
