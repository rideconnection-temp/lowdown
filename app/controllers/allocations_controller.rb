class AllocationsController < ApplicationController
  
  before_filter :get_drop_down_data, :only => [:new, :edit]
  
  def index
    @allocations = Allocation.includes(:project, :provider).order('providers.name, allocations.name')
    respond_to do |format|
      format.html do
        @allocations = @allocations.paginate :page => params[:page]
        @grouped_allocations = @allocations.group_by(&:provider_name)
      end
      format.csv
    end
  end
  
  def new
    @allocation = Allocation.new
  end
  
  def create
    @allocation = Allocation.new params[:allocation]

    if @allocation.save
      redirect_to(allocations_path, :notice => 'Allocation was successfully created.')
    else
      get_drop_down_data
      render :action => "new"
    end
  end

  def edit
    @allocation = Allocation.find params[:id]
  end

  def update
    @allocation = Allocation.find(params[:id])

    if @allocation.update_attributes(params[:allocation])
      redirect_to(edit_allocation_path(@allocation), :notice => 'Allocation was successfully updated.')
    else
      get_drop_down_data
      render :action => "edit"
    end
  end
  
  def destroy
    @allocation = Allocation.find params[:id]
    @allocation.destroy if current_user.is_admin && !(@allocation.trips.exists? || @allocation.summaries.exists?)
    
    redirect_to allocations_url
  end

  private
  
  def get_drop_down_data
    @trip_collection_methods   = Allocation.all.map(&:trip_collection_method).uniq
    @run_collection_methods    = Allocation.all.map(&:run_collection_method).uniq
    @cost_collection_methods   = Allocation.all.map(&:cost_collection_method).uniq
    @trimet_providers          = TrimetProvider.default_order
    @trimet_programs           = TrimetProgram.default_order
    @trimet_report_group       = TrimetReportGroup.default_order
  end
end
