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
    @summary.save!
    if @summary
      redirect_to(:action=>:show_update, :id=>@summary.id)
    else
      @providers = Provider.all
      @allocations = Allocation.all
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

    @providers = Provider.all
    @allocations = Allocation.all
    @summary.update_attributes(params[:summary]) ?
      redirect_to(:action=>:show_update, :id=>@summary) : render(:action => :show_update)
  end

end
