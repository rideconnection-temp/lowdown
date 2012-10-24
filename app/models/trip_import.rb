require 'csv'
require 'bigdecimal'

class CSV
  Converters={ integer:   lambda { |f|
      Integer(f.encode(ConverterEncoding)) rescue f
    },
    float:     lambda { |f|
      Float(f.encode(ConverterEncoding)) rescue f
    },
    numeric:   [:integer, :float],
    date:      lambda { |f|
      begin
        e = f.encode(ConverterEncoding)
        e =~ DateMatcher ? Date.parse(e) : f
      rescue  # encoding conversion or date parse errors
        f
      end
    },
    date_time: lambda { |f|
      begin
        e = f.encode(ConverterEncoding)
        e =~ DateTimeMatcher ? DateTime.parse(e) : f
      rescue  # encoding conversion or date parse errors
        f
      end
    },
    money:  lambda { |f| 
      begin
        f =~ /^\d+\.\d\d$/ ? BigDecimal.new(f) : f
      rescue
        f
      end
    },
    all:       [:date_time, :money, :numeric]
  }
end

class TripImport < ActiveRecord::Base
  attr_accessor :record_count
  attr_accessor :import_start_time
  attr_accessor :problems
  has_many :trips
  has_many :runs

  before_create :import_file, :apportion_imported_shared_rides 
  after_create :associate_records_with_trip_import
private

  def import_file

    headers = [:routematch_customer_id, :last_name, :first_name, :middle_initial, 
        :sex, :race, :mobility, :veteran_status,
        :telephone_1, :telephone_1_ext, :telephone_2, :telephone_2_ext, 
        :home_routematch_address_id, :home_common_name, :home_building_name, 
        :home_address_1, :home_address_2, :home_city, :home_state, :home_postal_code, 
        :home_x_coordinate, :home_y_coordinate, :home_in_trimet_district, 
        :language_preference, :birthdate, :email, :customer_type, :monthly_household_income, :household_size,
        :prime_number, :case_manager, :case_manager_office, :date_enrolled, :service_end, :approved_rides,
        :routematch_run_id, :run_name, :run_start_at, :run_end_at, :run_odometer_start, :run_odometer_end, :escort_count,
        :routematch_trip_id, :date, 
        :provider_code, :provider_name, :provider_type, 
        :result_code, :start_at, :end_at, :odometer_start, :odometer_end,
        :trip_duration, :trip_mileage,
        :fare, :customer_pay, :trip_purpose_type, :guest_count, :attendant_count, :trip_mobility, 
        :calculated_bpa_fare, :bpa_driver_name, :volunteer_trip, :in_trimet_district, 
        :bpa_billing_distance, :routematch_share_id, :override, :original_override,
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
    import_errors = []
    run_map = {}
    self.problems = ''
    self.import_start_time = Time.xmlschema(Time.now.xmlschema)
    @record_count = -1
    allocations = Allocation.for_import

    # Check for bad allocation mappings before anything else.
    CSV.foreach(file_path, headers: headers, converters: :all) do |record|
      @record_count += 1
      next if @record_count == 0

      current_allocation = allocations.detect{|a| a.name == record[:override] && a.routematch_provider_code == record[:provider_code] && a.activated_on.to_date <= record[:date] && (a.inactivated_on.blank? || a.inactivated_on.to_date > record[:date])}
      if current_allocation.nil? && record[:result_code] != 'TD'
        import_errors_key = "#{record[:override]}|#{record[:provider_code]}"
        unless import_errors.include?(import_errors_key) 
          import_errors << import_errors_key
          self.problems << "No allocation found for override '#{record[:override]}' and provider '#{record[:provider_code]}'.<br/>" 
        end
      end
    end
    return false unless self.problems == ''

    @record_count = -1
    if import_errors.blank?
      ActiveRecord::Base.transaction do
        CSV.foreach(file_path, headers: headers, converters: :all) do |record|
          @record_count += 1
          next if @record_count == 0 
          next if record[:routematch_customer_id].nil?

          current_allocation = allocations.detect{|a| a.name == record[:override] && a.routematch_provider_code == record[:provider_code] && a.activated_on <= record[:date] && (a.inactivated_on.blank? || a.inactivated_on > record[:date])}
          next if current_allocation.nil?

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
            current_home.in_trimet_district = make_boolean(record[:home_in_trimet_district])
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
            current_customer.veteran_status = record[:veteran_status]
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
            current_customer.prime_number = record[:prime_number]
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
            current_pickup.in_trimet_district = make_boolean(record[:pickup_in_trimet_district])
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
            current_dropoff.in_trimet_district = make_boolean(record[:dropoff_in_trimet_district])
            current_dropoff.save!

            current_dropoff_id = current_dropoff.id
            address_map[record[:dropoff_routematch_address_id]] = current_dropoff_id
          end

          if current_allocation.present?
            # Don't collect runs when we don't collect anything about them.
            if current_allocation.run_collection_method == 'runs' 
              if record[:routematch_run_id].present?
                if run_map.has_key?(record[:routematch_run_id])
                  current_run_id = run_map[record[:routematch_run_id]]
                else
                  current_run = Run.current_versions.find_or_initialize_by_routematch_id(record[:routematch_run_id])
                  current_run.name = record[:run_name]
                  current_run.date = record[:date]
                  current_run.start_at = record[:run_start_at]
                  current_run.end_at = record[:run_end_at]
                  current_run.odometer_start = record[:run_odometer_start]
                  current_run.odometer_end = record[:run_odometer_end]
                  current_run.escort_count = record[:escort_count]
                  current_run.bulk_import = true
                  if current_run.changed?
                    current_run.imported_at = import_start_time 
                    current_run.version_switchover_time = import_start_time
                    current_run.save! 
                  end

                  current_run_id = current_run.id
                  run_map[record[:routematch_run_id]] = current_run_id
                end
              else # Trips that didn't happen are brought together in one 'Not completed' for a day run
                runless_trips_run_key = record[:date].to_s + record[:override]
                if run_map.has_key?(runless_trips_run_key)
                  current_run_id = run_map[runless_trips_run_key]
                else
                  current_run = Run.new
                  current_run.name = 'Not completed ' + record[:date].to_time.strftime("%m-%d-%y")
                  current_run.date = record[:date]
                  if current_run.changed?
                    current_run.imported_at = import_start_time 
                    current_run.version_switchover_time = import_start_time
                    current_run.save! 
                  end

                  current_run_id = current_run.id
                  run_map[runless_trips_run_key] = current_run_id
                end
              end
            end

            current_trip = Trip.current_versions.find_or_initialize_by_routematch_trip_id(record[:routematch_trip_id])
            current_trip.routematch_trip_id = record[:routematch_trip_id]
            current_trip.date = record[:date]
            current_trip.result_code = record[:result_code]
            current_trip.allocation_id = current_allocation.id
            current_trip.provider_code = record[:provider_code]
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
            if record[:calculated_bpa_fare] =~ /^\d+\.\d\d;\d+\.\d\d$/
              fare_parts = record[:calculated_bpa_fare].split(";")
              current_trip.calculated_bpa_fare = BigDecimal.new(fare_parts[0])
              current_trip.estimated_individual_fare = BigDecimal.new(fare_parts[1])
            else
              current_trip.calculated_bpa_fare = record[:calculated_bpa_fare]
            end
            current_trip.bpa_driver_name = record[:bpa_driver_name]
            current_trip.volunteer_trip = make_boolean(record[:volunteer_trip])
            current_trip.in_trimet_district = make_boolean(record[:in_trimet_district])
            current_trip.bpa_billing_distance = record[:bpa_billing_distance]
            current_trip.routematch_share_id = record[:routematch_share_id]
            current_trip.override = record[:override]
            current_trip.original_override = record[:original_override]
            current_trip.estimated_trip_distance_in_miles = record[:estimated_trip_distance_in_miles]
            current_trip.routematch_pickup_address_id = record[:pickup_routematch_address_id]
            current_trip.routematch_dropoff_address_id = record[:dropoff_routematch_address_id]
            current_trip.case_manager = record[:case_manager]
            current_trip.approved_rides = record[:approved_rides]
            current_trip.date_enrolled = record[:date_enrolled]
            current_trip.service_end = record[:service_end]
            current_trip.case_manager_office = record[:case_manager_office]
            current_trip.pickup_address_id = current_pickup_id
            current_trip.dropoff_address_id = current_dropoff_id
            current_trip.customer_id = current_customer_id
            current_trip.customer_type = record[:customer_type]
            current_trip.home_address_id = current_home_id
            current_trip.run_id = current_run_id
            current_trip.bulk_import = true
            current_trip.imported_at = import_start_time 
            current_trip.version_switchover_time = import_start_time
            # apportionment for run-based trips is done before import.  This helps assure that the
            # Reporting Services reports and the Service DB reports match exactly.
            if current_allocation.run_collection_method == 'runs'
              current_trip.apportioned_duration = record[:trip_duration] * 60 if record[:trip_duration].present?
              current_trip.apportioned_mileage = record[:trip_mileage]
            end
            current_trip.save! if current_trip.new_record? || (current_trip.changed != ['imported_at'])
          end # current_allocation.present?
        end # CSV.foreach
      end # Transaction
    end
    address_map = nil
    customer_map = nil
    run_map = nil
  end

  #This should trigger the apportion_shared_rides callback in the trips model.  
  def apportion_imported_shared_rides
    trips = Trip.current_versions.where(:imported_at => self.import_start_time).completed.shared.order(:date,:routematch_share_id)
    trip_count = 0
    this_share_id = 0
    for trip in trips
      if trip.routematch_share_id != this_share_id 
        this_share_id = trip.routematch_share_id 
        trip.do_not_version = true
        trip.save!
        trip_count += 1
      end
    end
    trips = nil
    puts "Apportioned #{trip_count} shared rides"
  end

  # Not needed, as apportioning is handled prior to import.
  def apportion_imported_runs
    runs = Run.current_versions.where(:imported_at => self.import_start_time).has_odometer_log.has_time_log
    run_count = 0
    for run in runs
      run.do_not_version = true
      run.save!
      run_count += 1
    end
    puts "Apportioned #{run_count} runs"
  end

  # Add the trip import id after the import is complete, once the id has been generated
  def associate_records_with_trip_import
    Run.where(:imported_at => self.import_start_time).update_all :trip_import_id => self.id
    Trip.where(:imported_at => self.import_start_time).update_all :trip_import_id => self.id
  end

  # Source data can have 1 or -1 as true. 0 and nil are false
  def make_boolean(value)
    if value.blank?
      false
    elsif value == 0
      false
    else
      true
    end
  end
end
