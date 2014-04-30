class TrimetReportGroupsController < ApplicationController
  
  before_filter :require_admin_user, except: [:index, :edit]

  def index
    @trimet_report_groups = TrimetReportGroup.default_order.paginate page: params[:page]
  end
  
  def new
    @trimet_report_group = TrimetReportGroup.new
  end
  
  def create
    @trimet_report_group = TrimetReportGroup.new safe_params

    if @trimet_report_group.save
      redirect_to(trimet_report_groups_path, notice: 'Report group was successfully created.')
    else
      render :new
    end
  end

  def edit
    @trimet_report_group = TrimetReportGroup.find params[:id]
  end

  def update
    @trimet_report_group = TrimetReportGroup.find(params[:id])

    if @trimet_report_group.update_attributes(safe_params)
      redirect_to(edit_trimet_report_group_path(@trimet_report_group), notice: 'Report group was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @trimet_report_group = TrimetReportGroup.find params[:id]
    @trimet_report_group.destroy if @trimet_report_group.allocations.empty? 
    
    redirect_to trimet_report_groups_url
  end

  private

    def safe_params
      params.require(:trimet_report_group).permit(:name)
    end
end
