class TrimetProgramsController < ApplicationController
  
  before_filter :require_admin_user, :except => [:index, :edit]

  def index
    @trimet_programs = TrimetProgram.default_order.paginate :page => params[:page]
  end
  
  def new
    @trimet_program = TrimetProgram.new
  end
  
  def create
    @trimet_program = TrimetProgram.new params[:trimet_program]

    if @trimet_program.save
      redirect_to(trimet_programs_path, :notice => 'Program was successfully created.')
    else
      render :action => "new"
    end
  end

  def edit
    @trimet_program = TrimetProgram.find params[:id]
  end

  def update
    @trimet_program = TrimetProgram.find(params[:id])

    if @trimet_program.update_attributes(params[:trimet_program])
      redirect_to(edit_trimet_program_path(@trimet_program), :notice => 'Program was successfully updated.')
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @trimet_program = TrimetProgram.find params[:id]
    @trimet_program.destroy
    
    redirect_to trimet_programs_url
  end
end
