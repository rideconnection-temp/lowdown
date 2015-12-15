class ReportRowAllocation
  attr_accessor :allocation,
                :year,
                :quarter,
                :month,
                :semimonth,
                :report_start_date,
                :report_after_end_date,
                :period_start_date,
                :period_after_end_date,
                :collection_start_date,
                :collection_after_end_date,
                :trip_purpose,
                :is_trip_purpose_allocation

  def self.method_missing(method_name, *args, &block)
    Allocation.send method_name, *args, &block
  end

  def self.apply_periods(allocations, period)
    # enumerate periods between start_date and after_end_date.
    # collection_*_date variables represent the date range we're going to collect data for.
    # period_*_date variables represent the entire period range (e.g. the full 12 months of the year).
    # collection date ranges will be a subset of the period range when the period range extends
    # before and/or after the date range requested by the user.
    star_date = allocations.first.report_start_date
    after_end_date = allocations.first.report_after_end
    year = start_date.year

    if period == 'year'
      if start_date.month < 7
        period_start_date = Date.new(year - 1, 7, 1)
      else
        period_start_date = Date.new(year, 7, 1)
      end
      advance = 12
    elsif period == 'quarter'
      zero_based_month = start_date.month - 1
      quarter_start = (zero_based_month / 3) * 3 + 1
      period_start_date = Date.new(year, quarter_start, 1)
      advance = 3
    elsif period == 'month'
      period_start_date = Date.new(year, start_date.month, 1)
      advance = 1
    elsif period == 'semimonth'
      period_start_date = Date.new(year, start_date.month, 1)
      advance = 0.5
    end
    if advance == 0.5
      period_after_end_date = period_start_date + 15
    else
      period_after_end_date = period_start_date.advance(months: advance)
    end

    periods = []
    begin
      collection_start_date = (start_date > period_start_date ? start_date : period_start_date)
      collection_after_end_date = (after_end_date < period_after_end_date ? after_end_date : period_after_end_date)

      periods += allocations.map do |allocation|
        ReportRowAllocation.new(
          report_start_date:          start_date,
          report_after_end_date:      end_date,
          allocation:                 allocation,
          period_start_date:          period_start_date,
          period_after_end_date:      period_after_end_date,
          collection_start_date:      collection_start_date,
          collection_after_end_date:  collection_after_end_date
        )
      end

      if advance == 0.5
        if period_start_date.day == 1
          period_after_end_date = period_start_date.advance(months: 1)
          period_start_date = period_start_date.change(day: 16)
        else
          period_start_date = period_after_end_date
          period_after_end_date = period_start_date.change(day: 16)
        end
      else
        period_start_date = period_start_date.advance(months: advance)
        period_after_end_date = period_after_end_date.advance(months: advance)
      end
    end while period_start_date < after_end_date

    periods
  end

  def self.apply_trip_purposes(allocations)
    allocations_before_trip_purposes = allocations.dup
    allocations_before_trip_purposes.each do |a|
      POSSIBLE_TRIP_PURPOSES.each do |this_trip_purpose|
        allocations << ReportRowAllocation.new(
          report_start_date:          a.report_start_date,
          report_after_end_date:      a.report_after_end_date,
          allocation:                 a.allocation,
          period_start_date:          a.period_start_date,
          period_after_end_date:      a.period_after_end_date,
          collection_start_date:      a.collection_start_date,
          collection_after_end_date:  a.collection_after_end_date,
          trip_purpose:               this_trip_purpose,
          is_trip_purpose_allocation: true
        )
      end
    end
    allocations
  end

  def initialize(
      report_start_date:          nil,
      report_after_end_date:      nil,
      allocation:                 nil,
      period_start_date:          nil,
      period_after_end_date:      nil,
      collection_start_date:      nil,
      collection_after_end_date:  nil,
      trip_purpose:               nil,
      is_trip_purpose_allocation: false
    )
    @report_start_date          = report_start_date
    @report_after_end_date      = report_after_end_date
    @allocation                 = allocation
    @period_start_date          = period_start_date
    @period_after_end_date      = period_after_end_date
    @trip_purpose               = trip_purpose
    @is_trip_purpose_allocation = is_trip_purpose_allocation
    if period_start_date.present?
      @collection_start_date      = collection_start_date
      @collection_after_end_date  = collection_after_end_date
      if period_start_date.month < 7
        @year = period_start_date.year - 1
      else
        @year = period_start_date.year
      end
      @quarter = period_start_date.year * 10 + (period_start_date.month - 1) / 3 + 1
      @month = period_start_date.year * 100 + period_start_date.month
      @semimonth = period_start_date.year * 10000 + period_start_date.month * 100 + period_start_date.day
    else
      @collection_start_date     = @report_start_date
      @collection_after_end_date = @report_after_end_date
    end
  end

  def is_period_allocation?
    @period_start_date.present?
  end

  def is_trip_purpose_allocation?
    @is_trip_purpose_allocation
  end

  def method_missing(method_name, *args, &block)
    @allocation.send method_name, *args, &block
  end

  def respond_to?(method)
    if instance_variables.member? "@#{method.to_s}".to_sym
      return true
    end
    return @allocation.respond_to? method
  end

  def ==(other)
    (
      @allocation.id              == other.id &&
      @period_start_date          == other.period_start_date &&
      @period_after_end_date      == other.period_after_end_date &&
      @collection_start_date      == other.collection_start_date &&
      @collection_after_end_date  == other.collection_after_end_date &&
      @trip_purpose               == other.trip_purpose &&
      @is_trip_purpose_allocation == other.is_trip_purpose_allocation
    )
  end
end
