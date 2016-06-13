class TrimetProvidersController < ApplicationController
  
  before_filter :require_admin_user, except: [:index, :edit]

  def index
    @trimet_providers = TrimetProvider.default_order.paginate page: params[:page]
  end
  
  def new
    @trimet_provider = TrimetProvider.new
  end
  
  def create
    @trimet_provider = TrimetProvider.new safe_params

    if @trimet_provider.save
      redirect_to(trimet_providers_path, notice: 'Provider was successfully created.')
    else
      render :new
    end
  end

  def edit
    @trimet_provider = TrimetProvider.find params[:id]
  end

  def update
    @trimet_provider = TrimetProvider.find(params[:id])

    if @trimet_provider.update_attributes(safe_params)
      redirect_to(edit_trimet_provider_path(@trimet_provider), notice: 'Provider was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @trimet_provider = TrimetProvider.find params[:id]
    @trimet_provider.destroy
    
    redirect_to trimet_providers_url
  end

  private

    def safe_params
      params.require(:trimet_provider).permit(:name, :trimet_identifier)
    end
end
