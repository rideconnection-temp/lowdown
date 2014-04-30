class CustomersController < ApplicationController

  before_filter :require_admin_user, except: [:show]

  def show
    @customer = Customer.find params[:id]
    @trips = @customer.trips.current_versions.paginate page: params[:page], per_page: 30
  end
  
  def update
    @customer = Customer.find params[:id]
    
    if @customer.update_attributes safe_params
      redirect_to @customer, notice: 'Customer was successfully updated.'
    else
      render :show
    end
  end

  private

    def safe_params
      params.require(:customer).permit(
        :last_name,
        :first_name,
        :middle_initial,
        :birthdate,
        :sex,
        :race,
        :veteran_status,
        :customer_type,
        :mobility,
        :email,
        :telephone_primary,
        :telephone_primary_extension,
        :telephone_secondary,
        :telephone_secondary_extension,
        :language_preference,
        :prime_number
      )
    end
end
