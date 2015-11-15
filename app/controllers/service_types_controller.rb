class ServiceTypesController < ApplicationController

  before_filter :require_admin_user, except: [:index, :edit]
  
  def index
    @service_types = ServiceType.default_order.paginate page: params[:page]
  end
  
  def new
    @service_type = ServiceType.new
  end
  
  def create
    @service_type = ServiceType.new safe_params

    if @service_type.save
      redirect_to(service_types_path, notice: 'Service type was successfully created.')
    else
      render :new
    end
  end

  def edit
    @service_type = ServiceType.find params[:id]
  end

  def update
    @service_type = ServiceType.find(params[:id])

    if @service_type.update_attributes(safe_params)
      redirect_to(edit_service_type_path(@service_type), notice: 'Service type was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @service_type = ServiceType.find params[:id]
    @service_type.destroy if @service_type.allocations.empty? 
    
    redirect_to service_types_url
  end

  private

    def safe_params
      params.require(:service_type).permit(:name)
    end
end
