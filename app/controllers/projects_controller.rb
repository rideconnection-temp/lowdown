class ProjectsController < ApplicationController
  
  before_filter :require_admin_user, except: [:index, :edit]
  
  def index
    @projects = Project.default_order.paginate page: params[:page]
  end
  
  def new
    @project = Project.new
  end
  
  def create
    @project = Project.new safe_params

    if @project.save
      redirect_to(projects_path, notice: 'Project was successfully created.')
    else
      render :new
    end
  end

  def edit
    @project = Project.find params[:id]
  end

  def update
    @project = Project.find(params[:id])

    if @project.update_attributes(safe_params)
      redirect_to(edit_project_path(@project), notice: 'Project was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @project = Project.find params[:id]
    @project.destroy if @project.allocations.empty?
    
    redirect_to projects_url
  end
 
  private

    def safe_params
      params.require(:project).permit(:name, :project_number, :funding_source_id)
    end
end
