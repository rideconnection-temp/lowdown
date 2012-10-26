class ReportCategoriesController < ApplicationController
  
  before_filter :require_admin_user, :except => [:index, :edit]

  def index
    @report_categories = ReportCategory.default_order.paginate :page => params[:page]
  end
  
  def new
    @report_category = ReportCategory.new
  end
  
  def create
    @report_category = ReportCategory.new params[:report_category]

    if @report_category.save
      redirect_to(report_categories_path, :notice => 'Category was successfully created.')
    else
      render :action => "new"
    end
  end

  def edit
    @report_category = ReportCategory.find params[:id]
  end

  def update
    @report_category = ReportCategory.find(params[:id])

    if @report_category.update_attributes(params[:report_category])
      redirect_to(edit_report_category_path(@report_category), :notice => 'Program was successfully updated.')
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @report_category = ReportCategory.find params[:id]
    @report_category.destroy
    
    redirect_to report_categories_url
  end
end
