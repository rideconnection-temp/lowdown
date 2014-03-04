class ProjectsController < ApplicationController
  
  before_filter :require_admin_user, except: [:index, :edit]
  
  def index
    @projects = Project.default_order.paginate page: params[:page]
  end
  
  def new
    @project = Project.new
  end
  
  def create
    @project = Project.new params[:project]

    if @project.save
      redirect_to(projects_path, notice: 'Project was successfully created.')
    else
      get_drop_down_data
      render :new
    end
  end

  def edit
    @project = Project.find params[:id]
  end

  def update
    @project = Project.find(params[:id])

    if @project.update_attributes(params[:project])
      redirect_to(edit_project_path(@project), notice: 'Project was successfully updated.')
    else
      get_drop_down_data
      render :edit
    end
  end
  
  def destroy
    @project = Project.find params[:id]
    @project.destroy if @project.allocations.empty?
    
    redirect_to projects_url
  end
  
end
