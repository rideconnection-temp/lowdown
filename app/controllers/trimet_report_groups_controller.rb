class TrimetReportGroupsController < ApplicationController
  
  def index
    @trimet_report_groups = TrimetReportGroup.default_order.paginate :page => params[:page]
  end
  
  def new
    @trimet_report_group = TrimetReportGroup.new
  end
  
  def create
    @trimet_report_group = TrimetReportGroup.new params[:trimet_report_group]

    if @trimet_report_group.save
      redirect_to(trimet_report_groups_path, :notice => 'Report group was successfully created.')
    else
      render :action => "new"
    end
  end

  def edit
    @trimet_report_group = TrimetReportGroup.find params[:id]
  end

  def update
    @trimet_report_group = TrimetReportGroup.find(params[:id])

    if @trimet_report_group.update_attributes(params[:trimet_report_group])
      redirect_to(edit_trimet_report_group_path(@trimet_report_group), :notice => 'Report group was successfully updated.')
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @trimet_report_group = TrimetReportGroup.find params[:id]
    @trimet_report_group.destroy
    
    redirect_to trimet_report_groups_url
  end
end
