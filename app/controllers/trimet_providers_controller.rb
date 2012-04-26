class TrimetProvidersController < ApplicationController
  
  def index
    @trimet_providers = TrimetProvider.default_order.paginate :page => params[:page]
  end
  
  def new
    @trimet_provider = TrimetProvider.new
  end
  
  def create
    @trimet_provider = TrimetProvider.new params[:trimet_provider]

    if @trimet_provider.save
      redirect_to(trimet_providers_path, :notice => 'Provider was successfully created.')
    else
      render :action => "new"
    end
  end

  def edit
    @trimet_provider = TrimetProvider.find params[:id]
  end

  def update
    @trimet_provider = TrimetProvider.find(params[:id])

    if @trimet_provider.update_attributes(params[:trimet_provider])
      redirect_to(edit_trimet_provider_path(@trimet_provider), :notice => 'Provider was successfully updated.')
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @trimet_provider = TrimetProvider.find params[:id]
    @trimet_provider.destroy
    
    redirect_to trimet_providers_url
  end
end
