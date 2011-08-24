class AllocationsController < ApplicationController
  
  def index
    @allocations               = Allocation.paginate :page => params[:page]
  end

  def edit
    @allocation = Allocation.find params[:id]
    
    @trip_collection_methods   = Allocation.all.map(&:trip_collection_method).uniq
    @run_collection_methods    = Allocation.all.map(&:run_collection_method).uniq
    @cost_collection_methods   = Allocation.all.map(&:cost_collection_method).uniq
    @routematch_overrides      = Allocation.all.map(&:routematch_override).uniq
    @routematch_provider_codes = Allocation.all.map(&:routematch_provider_code).uniq
  end

  def update
    @allocation = Allocation.find(params[:id])

    if @allocation.update_attributes(params[:allocation])
      redirect_to(edit_allocation_path(@allocation), :notice => 'Allocation was successfully updated.')
    else
      render :action => "edit"
    end
  end
end
