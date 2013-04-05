require 'csv'

class FlexReportsController < ApplicationController
  before_filter :require_admin_user, :except=>[:index, :show, :csv, :edit]

  def index
    @reports = FlexReport.includes(:report_category)
    respond_to do |format|
      format.html
      format.csv do 
        @filename = 'flex_reports.csv'
      end
    end
  end

  def new
    @report = FlexReport.new(params[:flex_report])
    prep_edit
  end

  def create
    @report = FlexReport.new_from_params params

    if @report.save
      if params[:view].present?
        redirect_to flex_report_path(@report)
      elsif params[:csv].present?
        redirect_to flex_report_path(@report, :csv => true)
      else
        flash[:notice] = "Saved \"#{@report.name}\""
        redirect_to edit_flex_report_path(@report.id)
      end
    else
      prep_edit
      render :action => :new
    end
  end

  # the results of the report
  def show
    @report = FlexReport.find params[:id]
    if params[:flex_report].present?
      @report.attributes = params[:flex_report].slice("start_date(3i)","start_date(2i)","start_date(1i)","end_date(3i)","end_date(2i)","end_date(1i)","pending") 
      @report.save
    end
    @report.attributes = params[:flex_report]
    @report.populate_results!

    request.format = :csv if params[:csv].present?
    respond_to do |format|
      format.html do
        prep_partial_edit
      end
      format.csv do 
        @filename = "#{@report.name.gsub('"','')}.csv"
      end
    end
  end

  def edit
    @report = FlexReport.find params[:id]
    prep_edit
  end

  def update
    @report = FlexReport.find params[:id]

    if @report.update_attributes params[:flex_report]
      if params[:view].present?
        redirect_to flex_report_path(@report)
      elsif params[:csv].present?
        redirect_to flex_report_path(@report, :csv => true)
      else
        flash[:notice] = "Updated \"#{@report.name}\""
        redirect_to edit_flex_report_path(@report.id)
      end
    else
      prep_edit
      render :action => :edit
    end
  end

  def destroy
    report = FlexReport.destroy params[:id]
    flash[:notice] = "Deleted #{report.name}"
    redirect_to :action => :index
  end
  
  def sort
    params[:flex_reports].each do |id, index|
      FlexReport.update_all(['position=?', index], ['id=?', id])
    end
    render :nothing => true
  end

  private

  def prep_partial_edit
    @group_bys = FlexReport::GroupBys.sort
    if @report.group_by.present?
      @group_bys = @group_bys << @report.group_by unless @group_bys.include? @report.group_by
    end
  end

  def prep_edit
    prep_partial_edit
    @funding_subsource_names  = [['<Select All>','']] + Project.funding_subsource_names
    @providers                = [['<Select All>','']] + Provider.providers_in_allocations.default_order.map {|x| [x.to_s, x.id]}
    @reporting_agencies       = [['<Select All>','']] + Provider.reporting_agencies.default_order.map {|x| [x.to_s, x.id]}
    @programs                 = [['<Select All>','']] + Program.default_order.map {|x| [x.name, x.id]}
    @county_names             = [['<Select All>','']] + Allocation.county_names
    @grouped_allocations = [] 
    Provider.order(:name).includes(:allocations).each do |p|
      @grouped_allocations << [p.name, p.allocations.map {|a| [a.select_label,a.id]}]
    end
    @grouped_allocations << ['<No provider>', Allocation.where(:provider_id => nil).map {|a| [a.name,a.id]}]
  end
end
