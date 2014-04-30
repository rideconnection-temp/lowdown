class FundingSourcesController < ApplicationController

  before_filter :require_admin_user, except: [:index, :edit]
  
  def index
    @funding_sources = FundingSource.default_order.paginate page: params[:page]
  end
  
  def new
    @funding_source = FundingSource.new
  end
  
  def create
    @funding_source = FundingSource.new safe_params

    if @funding_source.save
      redirect_to(funding_sources_path, notice: 'Funding source was successfully created.')
    else
      render :new
    end
  end

  def edit
    @funding_source = FundingSource.find params[:id]
  end

  def update
    @funding_source = FundingSource.find(params[:id])

    if @funding_source.update_attributes(safe_params)
      redirect_to(edit_funding_source_path(@funding_source), notice: 'Funding source was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @funding_source = FundingSource.find params[:id]
    @funding_source.destroy
    
    redirect_to funding_sources_url
  end

  private

    def safe_params
      params.require(:funding_source).permit(:funding_source_name, :funding_subsource_name, :notes)
    end
end
