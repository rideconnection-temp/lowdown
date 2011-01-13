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
    @summary = Summary.new(params[:summary])
    @summary.save ? redirect_to(:action=>:show_update, :id=>@summary.id) : render(:action => :show_create)
  end

  def show_update
    @sumary = Sumary.find params[:id]
    @providers = Providers.all
    @allocations = Allocation.all
  end

  def update
    @summary = Summary.find(params[:id])
    @summary.update_attributes(params[:summary]) ?
      redirect_to(:action=>:show_update, :id=>@summary) : render(:action => :show_update)
  end

end
