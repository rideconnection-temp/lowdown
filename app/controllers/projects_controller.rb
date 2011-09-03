class ProjectsController < ApplicationController
  
  before_filter :get_drop_down_data, :only => [:new, :edit]
  
  def index
    @projects = Project.paginate :page => params[:page]
  end
  
  def new
    @project = Project.new
  end
  
  def create
    @project = Project.new params[:project]

    if @project.save
      redirect_to(projects_path, :notice => 'Project was successfully created.')
    else
      get_drop_down_data
      render :action => "new"
    end
  end

  def edit
    @project = Project.find params[:id]
  end

  def update
    @project = Project.find(params[:id])

    if @project.update_attributes(params[:project])
      redirect_to(edit_project_path(@project), :notice => 'Project was successfully updated.')
    else
      get_drop_down_data
      render :action => "edit"
    end
  end
  
  private
  
  def get_drop_down_data
    @funding_subsources = Project.all.map(&:funding_subsource).uniq
    @funding_sources    = Project.all.map(&:funding_source).uniq
  end
end
