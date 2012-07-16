class SummaryQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :period_start
  attr_accessor :period_end

  attr_accessor :provider

  def convert_date(obj, base)
    Date.new(obj["#{base}(1i)"].to_i,obj["#{base}(2i)"].to_i)
  end

  def initialize(params)
    if params
      @period_start = params["period_start(1i)"] ? convert_date(params, "period_start") : Date.parse(params["period_start"])
      @period_end   = params["period_end(1i)"] ? convert_date(params, "period_end") : Date.parse(params["period_end"])
      @provider     = params[:provider].to_i if params[:provider].present?
    end
  end

  def persisted?
    false
  end

  def conditions
    arr = [""]
    if @period_start
      arr[0] = arr[0] << "period_start BETWEEN ? AND ?"
      arr += [@period_start, @period_end]
    end
    if provider && provider != 0
      arr[0] = arr[0] << "AND allocation_id IN (#{Allocation.where(:provider_id => provider).map(&:id).join(",")})"
    elsif provider && provider == 0
      arr[0] = arr[0] << "AND allocation_id IN (#{Allocation.where(:provider_id => nil).map(&:id).join(",")})"
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
      @query.period_end = Date.new(today.year, today.month)
      @query.period_start = @query.period_end.prev_month
      params[:summary_query] = {:period_start => @query.period_start.to_s,
        :period_end => @query.period_end.to_s}
    end

    na_provider = Provider.new(:name => "<Not Applicable>")
    na_provider.id = 0
    @providers = [na_provider] + Provider.default_order
    @summaries = Summary.current_versions.where(@query.conditions).includes(:allocation,:summary_rows).joins(:allocation).order('allocations.name,summaries.period_start').paginate :page => params[:page]
  end

  def new
    @summary = Summary.new
    
    POSSIBLE_TRIP_PURPOSES.each do |purpose|
      @summary.summary_rows.build(:purpose => purpose)
    end
    prep_edit 
  end

  def create
    @summary = Summary.new(params[:summary])
    if ! @summary.summary_rows.size == POSSIBLE_TRIP_PURPOSES.size * 2
      flash.now[:alert] = "You must fill in all summary rows (even if just with zeros)"
      render(:action => :new)
    end
    if @summary.save
      redirect_to(:action=>:edit, :id=>@summary.id)
    else
      prep_edit
      render(:action => :new)
    end
  end

  def bulk_update
    updated = 0

    @query = SummaryQuery.new(params[:summary_query])
    if @query.conditions.first.empty?
      flash[:alert] = "Cannot update without date range"
    else
      updated = Summary.current_versions.where(@query.conditions).data_entry_not_complete.update_all(:complete => true)
      flash[:alert] = "Updated #{updated} records"
    end
    redirect_to :action => :index, :summary_query => params[:summary_query]
  end

  def edit
    @summary = Summary.find params[:id]
    prep_edit
    @versions = @summary.versions.reverse
  end

  def update
    old_version = Summary.find(params[:summary][:id])
    @summary = old_version.current_version

    prep_edit
    @versions = @summary.versions.reverse

    #gather up the old row objects
    old_rows = @summary.summary_rows.map &:clone 

    @summary.attributes = params[:summary]
    if @summary.save
      #this created a new prior version, to which we want to reassign the
      #newly-created old-valued summary rows
      prev = @summary.previous
      if prev
        for row in old_rows
          row.summary_id=prev.id
          row.save!
        end
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
          SummaryRow.create(:summary_id=>@summary.id)
        end
      end
      redirect_to(:action=>:edit, :id=>@summary)
    else
      render(:action => :edit)
    end
  end
  
  def delete
    @summary = Summary.find params[:id]
    
    if @summary.versions.size == 1
      if @summary.latest?    
        @summary.summary_rows.each &:delete
        @summary.delete # avoid callbacks or else delete will be halted
      end
    
      redirect_to :action => :index, :notice => "Summary successfully deleted"
    else
      render :action => :edit, :notice => "All previous versions must be deleted first"
    end 
  end

  def delete_version
    @summary = Summary.find params[:id]
    
    unless @summary.latest?    
      @summary.summary_rows.each &:delete
      @summary.delete # avoid callbacks or else delete will be halted
    end
    
    redirect_to :action => :edit, :id => @summary.base_id
  end

private

  def prep_edit
    @grouped_allocations = [] 
    Provider.with_summary_data.order(:name).each do |p|
      @grouped_allocations << [p.name, p.active_non_trip_allocations.map {|a| [a.select_label,a.id]}]
    end
    @grouped_allocations << ['<No provider>', Allocation.non_trip_collection_method.not_recently_inactivated.where(:provider_id => nil).map {|a| [a.name,a.id]}]
  end
end
