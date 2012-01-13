class RidePurposeRow

  @@trip_purposes = POSSIBLE_TRIP_PURPOSES + ["Unspecified", "Total"]

  attr_accessor :county, :provider, :by_purpose

  def self.sum(rows, out=nil)
    if out.nil?
      out = RidePurposeRow.new
    end
    if rows.instance_of? Hash
      rows.each do |key, row|
        RidePurposeRow.sum(row, out)
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
    sql = "select
purpose_type as purpose, count(*) as trips from trips where result_code='COMP' 
and allocation_id=? and date between ? and ? and valid_end = ?
group by purpose_type; "

    rows = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Trip.end_of_time]))

    total = 0
    for row in rows
      total += row['trips'].to_i
      @by_purpose[TRIP_PURPOSE_TO_SUMMARY_PURPOSE[row['purpose']]] += row['trips'].to_i
    end
    @by_purpose["Total"] = total
  end

  def collect_by_summary(allocation, start_date, end_date)
    sql = "select
purpose, in_district_trips + out_of_district_trips as trips from
summary_rows, summaries
where summary_rows.summary_id = summaries.base_id and 
allocation_id=? and period_start >= ? and period_end <= ? and summaries.valid_end = ?
"

    rows = ActiveRecord::Base.connection.select_all(bind([sql, allocation['id'], start_date, end_date, Summary.end_of_time]))

    total = 0
    for row in rows
      total += row['trips'].to_i
      @by_purpose[row['purpose']] += row['trips'].to_i
    end
    @by_purpose["Total"] = total
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
