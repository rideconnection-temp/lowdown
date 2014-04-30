class TrimetProgramsController < ApplicationController
  
  before_filter :require_admin_user, except: [:index, :edit]

  def index
    @trimet_programs = TrimetProgram.default_order.paginate page: params[:page]
  end
  
  def new
    @trimet_program = TrimetProgram.new
  end
  
  def create
    @trimet_program = TrimetProgram.new safe_params

    if @trimet_program.save
      redirect_to(trimet_programs_path, notice: 'Program was successfully created.')
    else
      render :new
    end
  end

  def edit
    @trimet_program = TrimetProgram.find params[:id]
  end

  def update
    @trimet_program = TrimetProgram.find(params[:id])

    if @trimet_program.update_attributes(safe_params)
      redirect_to(edit_trimet_program_path(@trimet_program), notice: 'Program was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @trimet_program = TrimetProgram.find params[:id]
    @trimet_program.destroy if @trimet_program.allocations.empty? 
    
    redirect_to trimet_programs_url
  end

  private

    def safe_params
      params.require(:trimet_program).permit(:name, :trimet_identifier, :notes)
    end
end
