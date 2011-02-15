class CustomersController < ApplicationController

  before_filter :require_user

  def show_create_report

  end

  def report
    @start_date = Date.parse(params[:date])
    @end_date = @start_date.next_month
    @customers = Customer.find_by_sql(["select * from customers where id in (select customer_id from trips where trips.date between ? and ?)", @start_date, @end_date])

    @wc_approved_rides = Trip.joins(:customer).where("customers.mobility <> 'Ambulatory' and customers.mobility <> 'Unknown' and date between ? and ? ", @start_date, @end_date).count

    @nonwc_approved_rides = Trip.joins(:customer).where("customers.mobility = 'Ambulatory' and date between ? and ? ", @start_date, @end_date).count

    @wc_billed_rides = @nonwc_billed_rides = 0 #FIXME
    @wc_mileage = Trip.joins(:customer).where("customers.mobility <> 'Ambulatory' and customers.mobility <> 'Unknown' and date between ? and ? ", @start_date, @end_date).sum("apportioned_mileage")
    @nonwc_mileage = Trip.joins(:customer).where("customers.mobility = 'Ambulatory' and date between ? and ? ", @start_date, @end_date).sum("apportioned_mileage")

  end

end
