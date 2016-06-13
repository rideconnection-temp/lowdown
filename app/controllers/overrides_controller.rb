class OverridesController < ApplicationController

  before_filter :require_admin_user, except: [:index, :edit]
  
  def index
    @overrides = Override.default_order.paginate page: params[:page]
  end
  
  def new
    @override = Override.new
  end
  
  def create
    @override = Override.new safe_params

    if @override.save
      redirect_to(overrides_path, notice: 'Override was successfully created.')
    else
      render :new
    end
  end

  def edit
    @override = Override.find params[:id]
  end

  def update
    @override = Override.find(params[:id])

    if @override.update_attributes(safe_params)
      redirect_to(edit_override_path(@override), notice: 'Override was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @override = Override.find params[:id]
    @override.destroy if @override.allocations.empty? 
    
    redirect_to overrides_url
  end

  private

    def safe_params
      params.require(:override).permit(:name)
    end
end
