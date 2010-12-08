class TripImport < ActiveRecord::Base
  require 'csv'


  def self.import_file(input_file)

    headers = [:routematch_customer_id, :last_name, :first_name, :middle_initial, :sex, :race, :mobility, 
        :telephone_1, :telephone_1_ext, :telephone_2, :telephone_2_ext, 
        :home_routematch_address_id, :home_common_name, :home_building_name, 
        :home_address_1, :home_address_2, :home_city, :home_state, :home_postal_code, 
        :home_x_coordinate, :home_y_coordinate, :home_in_trimet_district, 
        :language_preference, :birthdate, :email, :customer_type, :monthly_household_income, :household_size,
        :routematch_run_id, :run_name, :run_start_at, :run_end_at, :run_odometer_start, :run_odometer_end,
        :routematch_trip_id, :date, 
        :provider_code, :provider_name, :provider_type, 
        :result_code, :start_at, :end_at, :odometer_start, :odometer_end,
        :fare, :customer_pay, :trip_purpose_type, :guest_count, :attendant_count, :trip_mobility, 
        :calculated_bpa_fare, :bpa_driver_name, :volunteer_trip, :in_trimet_district, 
        :bpa_billing_distance, :routematch_share_id, :override, 
        :pickup_routematch_address_id, :pickup_common_name, :pickup_building_name, 
        :pickup_address_1, :pickup_address_2, :pickup_city, :pickup_state, :pickup_postal_code, 
        :pickup_x_coordinate, :pickup_y_coordinate, :pickup_in_trimet_district, 
        :dropoff_routematch_address_id, :dropoff_common_name, :dropoff_building_name, 
        :dropoff_address_1, :dropoff_address_2, :dropoff_city, :dropoff_state, :dropoff_postal_code, 
        :dropoff_x_coordinate, :dropoff_y_coordinate, :dropoff_in_trimet_district, 
        :estimated_trip_distance_in_miles]
    address_map = {}
    customer_map = {}
    provider_map = {}
    allocation_map = {}
    run_map = {}
    record_count = 0

    ActiveRecord::Base.transaction do
      CSV.foreach(input_file, headers: headers, converters: :all) do |record|
        
        record_count += 1

        next if record[:routematch_customer_id].nil?

        # For each address in the import, make it overwrite the previous version in this database
        # Do this only with the first occurance of the address.  Cache in memory the mapping between
        # the routematch address_id and the local id, so we don't need to touch the address record again.
        if address_map.has_key?(record[:home_routematch_address_id])
          current_home_id = address_map[record[:home_routematch_address_id]]
        else
          current_home = Address.find_or_initialize_by_routematch_address_id(record[:home_routematch_address_id])
          current_home.routematch_address_id = record[:home_routematch_address_id]
          current_home.common_name = record[:home_common_name]
          current_home.building_name = record[:home_building_name]
          current_home.address_1 = record[:home_address_1]
          current_home.address_2 = record[:home_address_2]
          current_home.city = record[:home_city]
          current_home.state = record[:home_state]
          current_home.postal_code = record[:home_postal_code]
          current_home.x_coordinate = record[:home_x_coordinate]
          current_home.y_coordinate = record[:home_y_coordinate]
          current_home.in_trimet_district = record[:home_in_trimet_district]
          current_home.save!
          
          # Add this new address to the map cache
          current_home_id = current_home.id
          address_map[record[:home_routematch_address_id]] = current_home_id
        end

        # Same as in addresses
        if customer_map.has_key?(record[:routematch_customer_id])
          current_customer_id = customer_map[record[:routematch_customer_id]]
        else
          current_customer = Customer.find_or_initialize_by_routematch_customer_id(record[:routematch_customer_id])
          current_customer.routematch_customer_id = record[:routematch_customer_id]
          current_customer.last_name = record[:last_name]
          current_customer.first_name = record[:first_name]
          current_customer.middle_initial = record[:middle_initial]
          current_customer.sex = record[:sex]
          current_customer.race = record[:race]
          current_customer.mobility = record[:mobility]
          current_customer.telephone_primary = record[:telephone_1]
          current_customer.telephone_primary_extension = record[:telephone_1_ext]
          current_customer.telephone_secondary = record[:telephone_2]
          current_customer.telephone_secondary_extension = record[:telephone_2_ext]
          current_customer.language_preference = record[:language_preference]
          current_customer.birthdate = record[:birthdate]
          current_customer.email = record[:email]
          current_customer.customer_type = record[:customer_type]
          current_customer.monthly_household_income = record[:monthly_household_income]
          current_customer.household_size = record[:household_size]
          current_customer.address_id = current_home_id
          current_customer.save!

          current_customer_id = current_customer.id
          customer_map[record[:routematch_customer_id]] = current_customer_id
        end

        if address_map.has_key?(record[:pickup_routematch_address_id])
          current_pickup_id = address_map[record[:pickup_routematch_address_id]]
        else
          current_pickup = Address.find_or_initialize_by_routematch_address_id(record[:pickup_routematch_address_id])
          current_pickup.routematch_address_id = record[:pickup_routematch_address_id]
          current_pickup.common_name = record[:pickup_common_name]
          current_pickup.building_name = record[:pickup_building_name]
          current_pickup.address_1 = record[:pickup_address_1]
          current_pickup.address_2 = record[:pickup_address_2]
          current_pickup.city = record[:pickup_city]
          current_pickup.state = record[:pickup_state]
          current_pickup.postal_code = record[:pickup_postal_code]
          current_pickup.x_coordinate = record[:pickup_x_coordinate]
          current_pickup.y_coordinate = record[:pickup_y_coordinate]
          current_pickup.in_trimet_district = record[:pickup_in_trimet_district]
          current_pickup.save!

          current_pickup_id = current_pickup.id
          address_map[record[:pickup_routematch_address_id]] = current_pickup_id
        end

        if address_map.has_key?(record[:dropoff_routematch_address_id])
          current_dropoff_id = address_map[record[:dropoff_routematch_address_id]]
        else
          current_dropoff = Address.find_or_initialize_by_routematch_address_id(record[:dropoff_routematch_address_id])
          current_dropoff.routematch_address_id = record[:dropoff_routematch_address_id]
          current_dropoff.common_name = record[:dropoff_common_name]
          current_dropoff.building_name = record[:dropoff_building_name]
          current_dropoff.address_1 = record[:dropoff_address_1]
          current_dropoff.address_2 = record[:dropoff_address_2]
          current_dropoff.city = record[:dropoff_city]
          current_dropoff.state = record[:dropoff_state]
          current_dropoff.postal_code = record[:dropoff_postal_code]
          current_dropoff.x_coordinate = record[:dropoff_x_coordinate]
          current_dropoff.y_coordinate = record[:dropoff_y_coordinate]
          current_dropoff.in_trimet_district = record[:dropoff_in_trimet_district]
          current_dropoff.save!

          current_dropoff_id = current_dropoff.id
          address_map[record[:dropoff_routematch_address_id]] = current_dropoff_id
        end

        if allocation_map.has_key?("#{record[:override]},#{record[:provider_code]}")
          current_allocation_id = allocation_map["#{record[:override]},#{record[:provider_code]}"]
        else
          current_allocation = Allocation.where(:routematch_override => record[:override], 
              :routematch_provider_code => record[:provider_code]).first
          raise "No allocation for override '#{record[:override]}' and provider '#{record[:provider_code]}'" if current_allocation.nil?
          current_allocation_id = current_allocation.id
          allocation_map["#{record[:override]},#{record[:provider_code]}"] = current_allocation.id
        end

        #if provider_map.has_key?(record[:provider_code]) 
        #  current_provider_id = provider_map[record[:provider_code]]
        #else
        #  current_provider_id = Provider.find_by_routematch_id(record[:provider_code]).id
        #  raise "Unknown provider code '#{record[:provider_code]}'" if current_provider_id.nil? 
        #  provider_map[record[:provider_code]] = current_provider_id
        #end

        if run_map.has_key?(record[:routematch_run_id])
          current_run_id = run_map[record[:routematch_run_id]]
        else
          current_run = Run.find_or_initialize_by_routematch_id(record[:routematch_run_id])
          current_run.name = record[:run_name]
          current_run.date = record[:date]
          current_run.start_at = record[:run_start_at]
          current_run.end_at = record[:run_end_at]
          current_run.odometer_start = record[:run_odometer_start]
          current_run.odometer_end = record[:run_odometer_end]
          current_run.save!

          current_run_id = current_run.id
          run_map[record[:routematch_run_id]] = current_run_id
        end

        current_trip = Trip.find_or_initialize_by_routematch_trip_id(record[:routematch_trip_id])
        current_trip.routematch_trip_id = record[:routematch_trip_id]
        current_trip.date = record[:date]
        current_trip.allocation_id = current_allocation_id
        current_trip.start_at = record[:start_at]
        current_trip.end_at = record[:end_at]
        current_trip.odometer_start = record[:odometer_start]
        current_trip.odometer_end = record[:odometer_end]
        current_trip.fare = record[:fare]
        current_trip.customer_pay = record[:customer_pay]
        current_trip.purpose_type = record[:trip_purpose_type]
        current_trip.guest_count = record[:guest_count]
        current_trip.attendant_count = record[:attendant_count]
        current_trip.mobility = record[:trip_mobility]
        current_trip.calculated_bpa_fare = record[:calculated_bpa_fare]
        current_trip.bpa_driver_name = record[:bpa_driver_name]
        current_trip.volunteer_trip = record[:volunteer_trip]
        current_trip.in_trimet_district = record[:in_trimet_district]
        current_trip.bpa_billing_distance = record[:bpa_billing_distance]
        current_trip.routematch_share_id = record[:routematch_share_id]
        current_trip.override = record[:override]
        current_trip.estimated_trip_distance_in_miles = record[:estimated_trip_distance_in_miles]
        current_trip.routematch_pickup_address_id = record[:pickup_routematch_address_id]
        current_trip.routematch_dropoff_address_id = record[:dropoff_routematch_address_id]
        current_trip.pickup_address_id = current_pickup_id
        current_trip.dropoff_address_id = current_dropoff_id
        current_trip.customer_id = current_customer_id
        current_trip.run_id = current_run_id
        current_trip.save!

        #puts "Record #{record_count}: Address map size: #{address_map.size.to_s}, Customer map size: #{customer_map.size.to_s}"
      end # CSV.foreach
    end # Transaction
    address_map = nil
    customer_map = nil
    record_count
  end 
end
