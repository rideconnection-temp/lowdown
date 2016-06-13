class ReportCategoriesController < ApplicationController
  
  before_filter :require_admin_user, except: [:index, :edit]

  def index
    @report_categories = ReportCategory.default_order.paginate page: params[:page]
  end
  
  def new
    @report_category = ReportCategory.new
  end
  
  def create
    @report_category = ReportCategory.new safe_params

    if @report_category.save
      redirect_to(report_categories_path, notice: 'Category was successfully created.')
    else
      render :new
    end
  end

  def edit
    @report_category = ReportCategory.find params[:id]
  end

  def update
    @report_category = ReportCategory.find(params[:id])

    if @report_category.update_attributes(safe_params)
      redirect_to(edit_report_category_path(@report_category), notice: 'Category was successfully updated.')
    else
      render :edit
    end
  end
  
  def destroy
    @report_category = ReportCategory.find params[:id]
    @report_category.destroy if @report_category.flex_reports.empty?
    
    redirect_to report_categories_url
  end

  private

    def safe_params
      params.require(:report_category).permit(:name)
    end
end
