class PeriodAllocation
  attr_accessor :year,
                :quarter,
                :month,
                :semimonth,
                :period_start_date,
                :period_after_end_date,
                :collection_start_date,
                :collection_after_end_date,
                :trip_purpose

  def self.apply_periods(allocations, start_date, after_end_date, period)
    # enumerate periods between start_date and after_end_date.
    # collection_*_date variables represent the date range we're going to collect data for.
    # period_*_date variables represent the entire period range (e.g. the full 12 months of the year).
    # collection date ranges will be a subset of the period range when the period range extends
    # before and/or after the date range requested by the user.
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
        PeriodAllocation.new allocation, period_start_date, period_after_end_date, collection_start_date, collection_after_end_date
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

  def initialize(
      allocation,
      period_start_date:          nil,
      period_after_end_date:      nil,
      collection_start_date:      nil,
      collection_after_end_date:  nil,
      trip_purpose:               nil
    )
    @allocation                 = allocation
    @period_start_date          = period_start_date
    @period_after_end_date      = period_after_end_date
    @collection_start_date      = collection_start_date
    @collection_after_end_date  = collection_after_end_date
    @trip_purpose               = trip_purpose
    if period_start_date.present?
      if period_start_date.month < 7
        @year = period_start_date.year - 1
      else
        @year = period_start_date.year
      end
      @quarter = period_start_date.year * 10 + (period_start_date.month - 1) / 3 + 1
      @month = period_start_date.year * 100 + period_start_date.month
      @semimonth = period_start_date.year * 10000 + period_start_date.month * 100 + period_start_date.day
    end
  end

  def is_period_allocation?
    @period_start_date.present?
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
      @trip_purpose               == other.trip_purpose
    )
  end
end
