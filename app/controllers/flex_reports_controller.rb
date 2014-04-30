class FlexReportsController < ApplicationController
  before_filter :require_admin_user, except: [:index, :show, :csv, :edit]

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
    @report = FlexReport.new(safe_params)
    if @report.save
      if params[:view].present?
        redirect_to flex_report_path(@report)
      elsif params[:csv].present?
        redirect_to flex_report_path(@report, csv: true)
      else
        flash[:notice] = "Saved \"#{@report.name}\""
        redirect_to edit_flex_report_path(@report.id)
      end
    else
      prep_edit
      render :new
    end
  end

  # The results of the report. Save the date range to make it the new default, but
  # don't save any other changes the user may make. Users get to fiddle with more 
  # substantial report attributes here, but have to go to the edit page to keep 
  # changes (if they have the rights to do so).
  def show
    @report = FlexReport.find params[:id]
    if params[:flex_report].present?
      @report.attributes = safe_params_for_show
      @report.save
      @report.attributes = safe_params
    end
    @report.populate_results!

    request.format = :csv if params[:csv].present?
    respond_to do |format|
      format.html { prep_edit }
      format.csv  { @filename = "#{@report.name.gsub('"','')}.csv" }
    end
  end

  def edit
    @report = FlexReport.find params[:id]
    prep_edit
  end

  def update
    @report = FlexReport.find params[:id]
    if @report.update_attributes safe_params
      if params[:view].present?
        redirect_to flex_report_path(@report)
      elsif params[:csv].present?
        redirect_to flex_report_path(@report, csv: true)
      else
        flash[:notice] = "Updated \"#{@report.name}\""
        redirect_to edit_flex_report_path(@report.id)
      end
    else
      prep_edit
      render :edit
    end
  end

  def destroy
    report = FlexReport.destroy params[:id]
    flash[:notice] = "Deleted #{report.name}"
    redirect_to flex_reports_path
  end
  
  private
  
    def safe_params_for_show
      params.require(:flex_report).permit(
        :start_date,
        :end_month,
        :pending
      )
    end

    def safe_params
      params.require(:flex_report).permit(
        :name,
        :description,
        :subtitle,
        :report_category_id,
        :group_by,
        :start_date,
        :end_month,
        :pending,
        :allocations => [],
        :funding_sources => [],
        :programs => [],
        :providers => [],
        :projects => [],
        :provider_type_names => [],
        :reporting_agencies => [],
        :reporting_agency_type_names => [],
        :county_names => [],
        :fields => [
          :funds,
          :agency_other,
          :vehicle_maint,
          :operations,
          :administrative,
          :donations,
          :total,
          :in_district_trips,
          :out_of_district_trips,
          :customer_trips,
          :guest_and_attendant_trips,
          :total_trips,
          :mileage,
          :driver_volunteer_hours,
          :driver_paid_hours,
          :driver_total_hours,
          :cost_per_trip,
          :cost_per_customer,
          :cost_per_mile,
          :cost_per_hour,
          :miles_per_ride,
          :miles_per_customer,
          :turn_downs,
          :undup_riders,
          :escort_volunteer_hours,
          :admin_volunteer_hours,
          :total_volunteer_hours
        ]
      )
    end

    def prep_edit
      @group_bys = FlexReport::GroupBys.sort
      if @report.group_by.present?
        @group_bys = @group_bys << @report.group_by unless @group_bys.include? @report.group_by
      end
      @funding_sources          = [['<All>','']] + FundingSource.default_order.map {|x| [x.name, x.id]}
      @projects                 = [['<All>','']] + Project.order(:project_number, :name).
                                  map {|x| [x.number_and_name, x.id]}
      @providers                = [['<All>','']] + Provider.providers_in_allocations.default_order.
                                  map {|x| [x.to_s, x.id]}
      @provider_types           = [['<All>','']] + Provider.providers_in_allocations.default_order.
                                  map {|x| [x.provider_type, x.provider_type]}.uniq.sort
      @reporting_agencies       = [['<All>','']] + Provider.reporting_agencies.default_order.
                                  map {|x| [x.to_s, x.id]}
      @reporting_agency_types   = [['<All>','']] + Provider.reporting_agencies.default_order.
                                  map {|x| [x.provider_type, x.provider_type]}.uniq.sort
      @programs                 = [['<All>','']] + Program.default_order.map {|x| [x.name, x.id]}
      @county_names             = [['<All>','']] + Allocation.county_names.map {|x| [x, x]}
      @grouped_allocations      = [] 
      Provider.order(:name).includes(:allocations).each do |p|
        @grouped_allocations << [p.name, p.allocations.map {|a| [a.select_label,a.id]}]
      end
      @grouped_allocations << ['<No provider>', Allocation.where(provider_id: nil).map {|a| [a.name,a.id]}]
    end
end
