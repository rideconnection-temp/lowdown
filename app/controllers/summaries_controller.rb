class SummariesController < ApplicationController
  before_filter :require_user
  before_filter :require_admin_user, :except=>[:index]

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
    clean_new_row
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

  def show_bulk_update
  end

  def bulk_update
    updated = 0

    start_day = params[:update]['start_date(1i)'].to_i
    start_month = params[:update]['start_date(2i)'].to_i
    start_year = params[:update]['start_date(3i)'].to_i
    start_date = Date.new(start_day, start_month, start_year)

    end_day = params[:update]['end_date(1i)'].to_i
    end_month = params[:update]['end_date(2i)'].to_i
    end_year = params[:update]['end_date(3i)'].to_i
    end_date = Date.new(end_day, end_month, end_year)

    for summary in Summary.current_versions.where("period_start >= ? and period_end < ?", start_date, end_date)
      updated += 1
      summary.complete = true
      summary.save!
    end
    flash[:notice] = "Updated #{updated} records"
    redirect_to :action=>:show_bulk_update
  end

  def show_update
    @summary = Summary.current_versions.find params[:id]
    @summary.summary_rows.build
    @providers = Provider.all
    @allocations = Allocation.all
  end

  def update
    @summary = Summary.current_versions.find(params[:summary][:id])
    clean_new_row

    @providers = Provider.all
    @allocations = Allocation.all
    @summary.update_attributes(params[:summary]) ?
      redirect_to(:action=>:show_update, :id=>@summary) : render(:action => :show_update)
  end

  private
  def clean_new_row

    #if the new row is not filled in, don't try to save it
    row_data = params[:summary][:summary_rows_attributes]
    last_row_index = (row_data.size - 1).to_s
    last_row = row_data[last_row_index]
    if last_row[:purpose].empty? && last_row[:trips].empty?
      row_data.delete(last_row_index)
    end
  end

end
