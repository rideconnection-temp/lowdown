class AllocationsController < ApplicationController
  
  before_filter :require_admin_user, except: [:index, :edit]
  
  def index
    @allocations = Allocation.includes(:project, :provider, :override).order('providers.name, allocations.name')
    respond_to do |format|
      format.html do
        @allocations = @allocations.paginate page: params[:page]
        @grouped_allocations = @allocations.group_by(&:provider_name)
      end
      format.csv do
        @filename = 'allocations.csv'
      end
    end
  end

  def new
    prep_edit
    @allocation = Allocation.new
  end
  
  def create
    @allocation = Allocation.new safe_params

    if @allocation.save
      redirect_to(allocations_path, notice: 'Allocation was successfully created.')
    else
      prep_edit
      render :new
    end
  end

  def edit
    prep_edit
    @allocation = Allocation.find params[:id]
  end

  def update
    @allocation = Allocation.find(params[:id])

    if @allocation.update_attributes(safe_params)
      redirect_to(edit_allocation_path(@allocation), notice: 'Allocation was successfully updated.')
    else
      prep_edit
      render :edit
    end
  end
  
  def destroy
    @allocation = Allocation.find params[:id]
    @allocation.destroy if current_user.is_admin && !(@allocation.trips.exists? || @allocation.summaries.exists?)
    
    redirect_to allocations_url
  end

  def trimet_groupings
    allocations = Allocation.in_trimet_groupings

    @trimet_groups = {}
    allocations.each do |a|
      @trimet_groups[[a.trimet_program,a.trimet_provider]] ||= []
      @trimet_groups[[a.trimet_program,a.trimet_provider]] << a
    end
    respond_to do |format|
      format.csv do
        @filename = 'TriMet Groupings.csv'
      end
    end
  end
  
  private

    def safe_params
      params.require(:allocation).permit(
        :name,
        :program_id,
        :project_id,
        :reporting_agency_id,
        :provider_id,
        :county,
        :trip_collection_method,
        :run_collection_method,
        :cost_collection_method,
        :volunteer_trip_collection_method,
        :override_id,
        :routematch_provider_code,
        :admin_ops_data,
        :vehicle_maint_data,
        :do_not_show_on_flex_reports,
        :eligibility,
        :trimet_provider_id,
        :trimet_program_id,
        :activated_on,
        :inactivated_on,
        :notes
      )
    end
  
    def prep_edit
      @trimet_providers          = TrimetProvider.default_order
      @trimet_programs           = TrimetProgram.default_order
    end
end
