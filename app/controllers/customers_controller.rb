class CustomersController < ApplicationController

  before_filter :require_admin_user, except: [:show]

  def show
    @customer = Customer.find params[:id]
    @trips = @customer.trips.current_versions.paginate page: params[:page], per_page: 30
  end
  
  def update
    @customer = Customer.find params[:id]
    
    if @customer.update_attributes params[:customer]
      redirect_to @customer, notice: 'Customer was successfully updated.'
    else
      render :show
    end
  end
end
