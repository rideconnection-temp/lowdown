module FiscalYear
  def fiscal_year_start_date(date)
    year = (date.month < 7 ? date.year - 1 : date.year)
    Date.new(year, 7, 1)
  end
end
