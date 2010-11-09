#!/usr/bin/ruby
require 'rubygems'
require 'fastercsv'

# This will parse a .csv file and create / update 
# Customers, Trips, and Addresses
#
# USAGE:
# For now, invoke from the command line and pass the desired CSV filename as an argument
# "parser.rb filename.csv"
#
# To pipe it directly into the app, use the following syntax:
# "parser.rb filename.csv|rails console production"
# (switch environment to development if appropriate)
#
# CURRENT EXPORT COLUMN HEADERS
# CustomerID
# CustomerLastName
# CustomerFirstName
# CustomerMiddleInitial
# Sex
# Race
# CustomerMobility
# Telephone1
# Telephone1Extension
# Telephone2
# Telephone2Extension
# LanguagePreference
# BirthDate
# Email
# CustomerType
# MonthlyHouseholdIncome
# HouseholdSize
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

input_file = ARGV[0]

  csv = FasterCSV.read(input_file)
  # Assumes headers
  fields = csv.shift

  csv.each do |record|
    next if record[0].nil?
    
    #Customer
    routematch_customer_id = record[0].to_i
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
    language_preference = record[11]
    begin
      birthdate = Date.parse(record[12]).to_s
    rescue
      birthdate = nil
    end
    email = record[13]
    customer_type = record[14]
    monthly_household_income = record[15].to_i
    household_size = record[16].to_i

    # Trip
    date = Date.parse(record[17], true).to_s
    cancelled = record[18]
    noshow = record[19]
    completed = record[20]
    start_at = DateTime.parse(record[21])
    end_at = DateTime.parse(record[22])
    odometer_start = record[23].to_i
    odometer_end = record[24].to_i
    fare = record[25]
    customer_pay = record[26]
    trip_purpose_type = record[27]
    guest_count = record[28].to_i
    attendant_count = record[29].to_i
    trip_mobility = record[30]
    trip_mobility_kind = record[31]
    calculated_bpa_fare = record[32]
    bpa_driver_name = record[33]
    volunteer_trip = record[34]
    in_trimet_district = record[35]
    bpa_billing_distance = record[36]
    routematch_share_id = record[37].to_i
    override = record[38]
    estimated_trip_distance_in_miles = record[61].to_i
    
    # Pickup Address
    pickup_routematch_address_id = record[39].to_i
    pickup_common_name = record[40]
    pickup_building_name = record[41]
    pickup_address_1 = record[42]
    pickup_address_2 = record[43]
    pickup_city = record[44]
    pickup_state = record[45]
    pickup_postal_code = record[46]
    pickup_x_coordinate = record[47]
    pickup_y_coordinate = record[48]
    pickup_in_trimet_district = record[49]
    
    # Dropoff Address
    dropoff_routematch_address_id = record[50].to_i
    dropoff_common_name = record[51]
    dropoff_building_name = record[52]
    dropoff_address_1 = record[53]
    dropoff_address_2 = record[54]
    dropoff_city = record[55]
    dropoff_state = record[56]
    dropoff_postal_code = record[57]
    dropoff_x_coordinate = record[58]
    dropoff_y_coordinate = record[59]
    dropoff_in_trimet_district = record[60]

  
    puts <<EOF
current_customer =Customer.find_or_initialize_by_routematch_customer_id("#{routematch_customer_id}")

# Do we want to only do writes if this is a new customer?
if current_customer.new_record?
  current_customer.routematch_customer_id = "#{routematch_customer_id}"
  current_customer.last_name = "#{last_name}"
  current_customer.first_name = "#{first_name}"
  current_customer.middle_initial = "#{middle_initial}"
  current_customer.sex = "#{sex}"
  current_customer.race = "#{race}"
  current_customer.mobility = "#{mobility}"
  current_customer.telephone_primary = "#{telephone_1}"
  current_customer.telephone_primary_extension = "#{telephone_1_ext}"
  current_customer.telephone_secondary = "#{telephone_2}"
  current_customer.telephone_secondary_extension = "#{telephone_2_ext}"
  current_customer.language_preference = "#{language_preference}"
  current_customer.birthdate = "#{birthdate}"
  current_customer.email = "#{email}"
  current_customer.customer_type = "#{customer_type}"
  current_customer.monthy_household_income = "#{monthly_household_income}"
  current_customer.household_size = "#{household_size}"
  # how determine residence?
  current_customer.save!
end

current_pickup = Address.find_or_initialize_by_routematch_address_id("#{pickup_routematch_address_id}")
# Do we want to only do writes if this is a new address?
if current_pickup.new_record?
  current_pickup.routematch_address_id = "#{pickup_routematch_address_id}"
  current_pickup.common_name = "#{pickup_common_name}"
  current_pickup.building_name = "#{pickup_building_name}"
  current_pickup.address_1 = "#{pickup_address_1}"
  current_pickup.address_2 = "#{pickup_address_2}"
  current_pickup.city = "#{pickup_city}"
  current_pickup.state = "#{pickup_state}"
  current_pickup.postal_code = "#{pickup_postal_code}"
  current_pickup.x_coordinate = "#{pickup_x_coordinate}"
  current_pickup.y_coordinate = "#{pickup_y_coordinate}"
  current_pickup.in_trimet_district = "#{pickup_in_trimet_district}"
  current_pickup.save!
end

current_dropoff = Address.find_or_initialize_by_routematch_address_id("#{dropoff_routematch_address_id}")
# Do we want to only do writes if this is a new address?
if current_dropoff.new_record?
  current_dropoff.routematch_address_id = "#{dropoff_routematch_address_id}"
  current_dropoff.common_name = "#{dropoff_common_name}"
  current_dropoff.building_name = "#{dropoff_building_name}"
  current_dropoff.address_1 = "#{dropoff_address_1}"
  current_dropoff.address_2 = "#{dropoff_address_2}"
  current_dropoff.city = "#{dropoff_city}"
  current_dropoff.state = "#{dropoff_state}"
  current_dropoff.postal_code = "#{dropoff_postal_code}"
  current_dropoff.x_coordinate = "#{dropoff_x_coordinate}"
  current_dropoff.y_coordinate = "#{dropoff_y_coordinate}"
  current_dropoff.in_trimet_district = "#{dropoff_in_trimet_district}"
  current_dropoff.save!
end


# How should we detect duplicate trips? Start and End datetime is probably too naive
current_trip = Trip.find_or_initialize_by_start_at_and_end_at("#{start_at}", "#{end_at}")

# Do we want to only do writes if this is a new trip?
if current_trip.new_record?
  current_trip.date = "#{date}"
  current_trip.cancelled = "#{cancelled}"
  current_trip.noshow = "#{noshow}"
  current_trip.completed = "#{completed}"
  current_trip.start_at = "#{start_at}"
  current_trip.end_at = "#{end_at}"
  current_trip.odometer_start = "#{odometer_start}"
  current_trip.odometer_end = "#{odometer_end}"
  current_trip.fare = "#{fare}"
  current_trip.customer_pay = "#{customer_pay}"
  current_trip.trip_purpose_type = "#{trip_purpose_type}"
  current_trip.guest_count = "#{guest_count}"
  current_trip.attendant_count = "#{attendant_count}"
  current_trip.trip_mobility = "#{trip_mobility}"
  current_trip.trip_mobility_kind = "#{trip_mobility_kind}"
  current_trip.calculated_bpa_fare = "#{calculated_bpa_fare}"
  current_trip.bpa_driver_name = "#{bpa_driver_name}"
  current_trip.volunteer_trip = "#{volunteer_trip}"
  current_trip.in_trimet_district = "#{in_trimet_district}"
  current_trip.bpa_billing_distance = "#{bpa_billing_distance}"
  current_trip.routematch_share_id = "#{routematch_share_id}"
  current_trip.override = "#{override}"
  current_trip.estimated_trip_distance_in_miles = "#{estimated_trip_distance_in_miles}"
  current_trip.pickup_address = current_pickup
  current_trip.routematch_pickup_address_id = "#{pickup_routematch_address_id}"
  current_trip.dropoff_address = current_dropoff
  current_trip.routematch_dropoff_address_id = "#{dropoff_routematch_address_id}"
  current_trip.save!
end

current_customer.trips<<current_trip
current_customer.save!
EOF

end