class ProvidersController < ApplicationController
  
  def index
    @providers = Provider.paginate :page => params[:page]
  end

  def edit
    @provider = Provider.find params[:id]
    
    @provider_types = Provider.all.map(&:provider_type).uniq
    # @run_collection_methods    = Provider.all.map(&:run_collection_method).uniq
    # @cost_collection_methods   = Provider.all.map(&:cost_collection_method).uniq
    # @routematch_overrides      = Provider.all.map(&:routematch_override).uniq
    # @routematch_provider_codes = Provider.all.map(&:routematch_provider_code).uniq
  end

  def update
    @provider = Provider.find(params[:id])

    if @provider.update_attributes(params[:provider])
      redirect_to(edit_provider_path(@provider), :notice => 'Provider was successfully updated.')
    else
      render :action => "edit"
    end
  end
end
