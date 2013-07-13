class TripPurposeRow

  @@trip_purposes = POSSIBLE_TRIP_PURPOSES + ["Unspecified", "Total"]

  attr_accessor :county, :provider, :by_purpose

  def self.sum(rows, out=nil)
    if out.nil?
      out = TripPurposeRow.new
    end
    if rows.instance_of? Hash
      rows.each do |key, row|
        TripPurposeRow.sum(row, out)
      end
    else
      out.include_row(rows)
    end
    return out
  end

  def initialize
    @by_purpose = {}
    for purpose in @@trip_purposes
      @by_purpose[purpose] = 0
    end
  end

  def collect_by_trip(allocation, start_date, end_date)
    rows = Trip.select("purpose_type as purpose, COUNT(*) + SUM(guest_count) + SUM(attendant_count) as trips").group("purpose_type").completed.for_allocation(allocation).for_date_range(start_date, end_date).current_versions
    for row in rows
      @by_purpose['Total'] += row.trips.to_i
      @by_purpose[TRIP_PURPOSE_TO_SUMMARY_PURPOSE[row['purpose']]] += row.trips.to_i
    end
  end

  def collect_by_summary(allocation, start_date, end_date)
    rows = Summary.select("purpose, in_district_trips, out_of_district_trips").joins(:summary_rows).for_allocation(allocation).for_date_range(start_date, end_date).current_versions
    for row in rows
      @by_purpose["Total"] += (row['in_district_trips'].to_i + row['out_of_district_trips'].to_i) 
      @by_purpose[row['purpose']] += (row['in_district_trips'].to_i + row['out_of_district_trips'].to_i)
    end
  end

  def include_row(row)
    for purpose in @@trip_purposes
      @by_purpose[purpose] += row.by_purpose[purpose]
    end
  end

  def percentages
    grand_total = @by_purpose["Total"]
    percentages = {}
    for purpose in @@trip_purposes
      percentages[purpose] = @by_purpose[purpose] * 100.0 / grand_total
    end
    percentages
  end

  def self.trip_purposes
    return @@trip_purposes
  end
end
