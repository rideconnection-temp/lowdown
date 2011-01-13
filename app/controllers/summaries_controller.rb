class SummariesController < ApplicationController

  def index
    @summaries = Summary.all
  end

  def show_create
    @summary = Summary.new
    @summary.summary_row.build
    @providers = Provider.all
    @allocations = Allocation.all
  end

  def create
    @summary = Summary.create(params[:summary]) 
    if @summary
      redirect_to(:action=>:show_update, :id=>@summary.id)
    else
      render(:action => :show_create)
    end
  end

  def show_update
    @summary = Summary.current_versions.find params[:id]
    @summary.summary_row.build
    @providers = Provider.all
    @allocations = Allocation.all
  end

  def update
    @summary = Summary.current_versions.find(params[:summary][:id])
    @summary.update_attributes(params[:summary]) ?
      redirect_to(:action=>:show_update, :id=>@summary) : render(:action => :show_update)
  end

end
