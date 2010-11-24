class TripImport < ActiveRecord::Base
  require 'csv'
# require 'fastercsv'

# This will parse a .csv file and create / update Customers, Trips, and Addresses
#
# USAGE:
# For now, invoke from the command line and pass the desired CSV filename as an argument
# "parser.rb filename.csv"
#
# To pipe it directly into the app, use the following syntax: 
# "parser.rb filename.csv|rails console production" (switch environment to development if appropriate)
#
# CURRENT EXPORT COLUMN HEADERS
# CustomerID
# CustomerLastName
# CustomerFirstName
# CustomerMiddleInitial
# Sex
# RaceID
# CustomerMobility
# Telephone1
# Telephone1Extension
# Telephone2
# Telephone2Extension
# HmAddressID
# HmCommonName
# HmBuildingName
# Address
# HmAddress1
# HmCity
# HmState
# HmZip
# HmXcoordinate
# HmYcoordinate
# HmIsInTriMetDistrict
# LanguagePreference
# BirthDate
# Email
# CustomerType
# MonthlyHouseholdIncome
# HouseholdSize
# TripID
# TripDate
# Cancelled
# NoShow
# Completed
# StartDateTime
# EndDateTime
# StartOdometer
# EndOdometer
# Fare
# CustomerPay
# TripPurposeType
# GuestCount
# AttendantCount
# TripMobility
# TripMobilityKind
# CalculatedBpaFare
# BpaDriverName
# IsVolunteerTrip
# IsInTriMetDistrict
# BpaBillingDistance
# ShareID
# Override
# PuAddressID
# PuCommonName
# PuBuildingName
# PuAddress
# PuAddress1
# PuCity
# PuState
# PuZip
# PuXcoordinate
# PuYcoordinate
# PuIsInTriMetDistrict
# DoAddressID
# DoCommonName
# DoBuildingName
# DoAddress
# DoAddress1
# DoCity
# DoState
# DoZip
# DoXcoordinate
# DoYcoordinate
# DoIsInTriMetDistrict
# EstTripDistanceInMiles

  def self.import_file(input_file)
    ActiveRecord::Base.transaction do
      CSV.foreach(input_file, headers: false, converters: :all) do |record|
        next if record[0].nil?

        #Customer
        routematch_customer_id = record[0]
        last_name = record[1]
        first_name = record[2]
        middle_initial = record[3]
        sex = record[4]
        race = record[5]
        mobility = record[6]
        telephone_1 = record[7]
        telephone_1_ext = record[8]
        telephone_2 = record[9]
        telephone_2_ext = record[10]

        # Home Address
        home_routematch_address_id = record[11]
        home_common_name = record[12]
        home_building_name = record[13]
        home_address_1 = record[14]
        home_address_2 = record[15]
        home_city = record[16]
        home_state = record[17]
        home_postal_code = record[18]
        home_x_coordinate = record[19]
        home_y_coordinate = record[20]
        home_in_trimet_district = record[21]

         # More Customer
        language_preference = record[22]
        #begin
          birthdate = record[23]
          #birthdate = Date.parse(record[23]).to_s
        #rescue
        #  birthdate = nil
        #end
        email = record[24]
        customer_type = record[25]
        monthly_household_income = record[26]
        household_size = record[27]

        # Trip
        routematch_trip_id = record[28]
        date = record[29]
        cancelled = record[30]
        noshow = record[31]
        completed = record[32]
        start_at = record[33]
        end_at = record[34]
        odometer_start = record[35]
        odometer_end = record[36]
        fare = record[37]
        customer_pay = record[38]
        trip_purpose_type = record[39]
        guest_count = record[40]
        attendant_count = record[41]
        trip_mobility = record[42]
        trip_mobility_kind = record[43]
        calculated_bpa_fare = record[44]
        bpa_driver_name = record[45]
        volunteer_trip = record[46]
        in_trimet_district = record[47]
        bpa_billing_distance = record[48]
        routematch_share_id = record[49]
        override = record[50]
        estimated_trip_distance_in_miles = record[73]

        # Pickup Address
        pickup_routematch_address_id = record[51]
        pickup_common_name = record[52]
        pickup_building_name = record[53]
        pickup_address_1 = record[54]
        pickup_address_2 = record[55]
        pickup_city = record[56]
        pickup_state = record[57]
        pickup_postal_code = record[58]
        pickup_x_coordinate = record[59]
        pickup_y_coordinate = record[60]
        pickup_in_trimet_district = record[61]

        # Dropoff Address
        dropoff_routematch_address_id = record[62]
        dropoff_common_name = record[63]
        dropoff_building_name = record[64]
        dropoff_address_1 = record[65]
        dropoff_address_2 = record[66]
        dropoff_city = record[67]
        dropoff_state = record[68]
        dropoff_postal_code = record[69]
        dropoff_x_coordinate = record[70]
        dropoff_y_coordinate = record[71]
        dropoff_in_trimet_district = record[72]

        # If a record already exists for this and the other tables in this import, just update it with all the fields
        current_home = Address.find_or_initialize_by_routematch_address_id(home_routematch_address_id)
        current_home.routematch_address_id = home_routematch_address_id
        current_home.common_name = home_common_name
        current_home.building_name = home_building_name
        current_home.address_1 = home_address_1
        current_home.address_2 = home_address_2
        current_home.city = home_city
        current_home.state = home_state
        current_home.postal_code = home_postal_code
        current_home.x_coordinate = home_x_coordinate
        current_home.y_coordinate = home_y_coordinate
        current_home.in_trimet_district = home_in_trimet_district
        current_home.save!

        current_customer = Customer.find_or_initialize_by_routematch_customer_id(routematch_customer_id)
        current_customer.routematch_customer_id = routematch_customer_id
        current_customer.last_name = last_name
        current_customer.first_name = first_name
        current_customer.middle_initial = middle_initial
        current_customer.sex = sex
        current_customer.race = race
        current_customer.mobility = mobility
        current_customer.telephone_primary = telephone_1
        current_customer.telephone_primary_extension = telephone_1_ext
        current_customer.telephone_secondary = telephone_2
        current_customer.telephone_secondary_extension = telephone_2_ext
        current_customer.language_preference = language_preference
        current_customer.birthdate = birthdate
        current_customer.email = email
        current_customer.customer_type = customer_type
        current_customer.monthy_household_income = monthly_household_income
        current_customer.household_size = household_size
        current_customer.primary_address = current_home
        current_customer.save!

        current_pickup = Address.find_or_initialize_by_routematch_address_id(pickup_routematch_address_id)
        current_pickup.routematch_address_id = pickup_routematch_address_id
        current_pickup.common_name = pickup_common_name
        current_pickup.building_name = pickup_building_name
        current_pickup.address_1 = pickup_address_1
        current_pickup.address_2 = pickup_address_2
        current_pickup.city = pickup_city
        current_pickup.state = pickup_state
        current_pickup.postal_code = pickup_postal_code
        current_pickup.x_coordinate = pickup_x_coordinate
        current_pickup.y_coordinate = pickup_y_coordinate
        current_pickup.in_trimet_district = pickup_in_trimet_district
        current_pickup.save!

        current_dropoff = Address.find_or_initialize_by_routematch_address_id(dropoff_routematch_address_id)
        current_dropoff.routematch_address_id = dropoff_routematch_address_id
        current_dropoff.common_name = dropoff_common_name
        current_dropoff.building_name = dropoff_building_name
        current_dropoff.address_1 = dropoff_address_1
        current_dropoff.address_2 = dropoff_address_2
        current_dropoff.city = dropoff_city
        current_dropoff.state = dropoff_state
        current_dropoff.postal_code = dropoff_postal_code
        current_dropoff.x_coordinate = dropoff_x_coordinate
        current_dropoff.y_coordinate = dropoff_y_coordinate
        current_dropoff.in_trimet_district = dropoff_in_trimet_district
        current_dropoff.save!

        current_trip = Trip.find_or_initialize_by_routematch_trip_id(routematch_trip_id)
        current_trip.routematch_trip_id = routematch_trip_id
        current_trip.date = date
        current_trip.cancelled = cancelled
        current_trip.noshow = noshow
        current_trip.completed = completed
        current_trip.start_at = start_at
        current_trip.end_at = end_at
        current_trip.odometer_start = odometer_start
        current_trip.odometer_end = odometer_end
        current_trip.fare = fare
        current_trip.customer_pay = customer_pay
        current_trip.trip_purpose_type = trip_purpose_type
        current_trip.guest_count = guest_count
        current_trip.attendant_count = attendant_count
        current_trip.trip_mobility = trip_mobility
        current_trip.trip_mobility_kind = trip_mobility_kind
        current_trip.calculated_bpa_fare = calculated_bpa_fare
        current_trip.bpa_driver_name = bpa_driver_name
        current_trip.volunteer_trip = volunteer_trip
        current_trip.in_trimet_district = in_trimet_district
        current_trip.bpa_billing_distance = bpa_billing_distance
        current_trip.routematch_share_id = routematch_share_id
        current_trip.override = override
        current_trip.estimated_trip_distance_in_miles = estimated_trip_distance_in_miles
        current_trip.pickup_address = current_pickup
        current_trip.routematch_pickup_address_id = pickup_routematch_address_id
        current_trip.dropoff_address = current_dropoff
        current_trip.routematch_dropoff_address_id = dropoff_routematch_address_id
        current_trip.save!

        current_customer.trips << current_trip
        current_customer.save!
      end # CSV.foreach
    end # Transaction
  end 
end
