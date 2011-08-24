class ProjectsController < ApplicationController
  
  def index
    @projects = Project.paginate :page => params[:page]
  end

  def edit
    @project = Project.find params[:id]
    
    @funding_subsources = Project.all.map(&:funding_subsource).uniq
    @funding_sources    = Project.all.map(&:funding_source).uniq
  end

  def update
    @project = Project.find(params[:id])

    if @project.update_attributes(params[:project])
      redirect_to(edit_project_path(@project), :notice => 'Project was successfully updated.')
    else
      render :action => "edit"
    end
  end
end
