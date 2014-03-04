class ProvidersController < ApplicationController
  before_filter :require_admin_user, except: [:index, :edit]
  
  def index
    @providers = Provider.default_order.paginate page: params[:page]
  end
  
  def new
    prep_edit
    @provider = Provider.new
  end
  
  def create
    @provider = Provider.new params[:provider]

    if @provider.save
      redirect_to(providers_path, notice: 'Provider was successfully created.')
    else
      get_drop_down_data
      render action: "new"
    end
  end

  def edit
    prep_edit
    @provider = Provider.find params[:id]
  end

  def update
    @provider = Provider.find(params[:id])

    if @provider.update_attributes(params[:provider])
      redirect_to(edit_provider_path(@provider), notice: 'Provider was successfully updated.')
    else
      prep_edit
      render action: "edit"
    end
  end
  
  def destroy
    @provider = Provider.find params[:id]
    @provider.destroy if @provider.allocations.empty? && @provider.allocations_as_reporting_agency.empty?
    
    redirect_to providers_url
  end
  
  private
  
  def prep_edit
    @provider_types = Provider::PROVIDER_TYPES
  end
end
