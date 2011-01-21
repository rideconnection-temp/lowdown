class SummariesController < ApplicationController
  before_filter :require_user

  def index
    @summaries = Summary.current_versions.all
  end

  def show_create
    @summary = Summary.new
    @summary.summary_rows.build
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
    @summary.summary_rows.build
    @providers = Provider.all
    @allocations = Allocation.all
  end

  def update
    @summary = Summary.current_versions.find(params[:summary][:id])

    #if the new row is not filled in, don't try to save it
    row_data = params[:summary][:summary_rows_attributes]
    last_row_index = (row_data.size - 1).to_s
    last_row = row_data[last_row_index]
    if last_row[:purpose].empty? && last_row[:trips].empty?
      row_data.delete(last_row_index)
    end

    @providers = Provider.all
    @allocations = Allocation.all
    @summary.update_attributes(params[:summary]) ?
      redirect_to(:action=>:show_update, :id=>@summary) : render(:action => :show_update)
  end

end
