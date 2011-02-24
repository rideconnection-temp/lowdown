class Date

  def add_months(months)
    the_year = self.year
    the_month = self.month + months
    while the_month < 0
      the_month += 12
      the_year -= 1
    end
    while the_month > 12
      the_month -= 12
      the_year += 1
    end
    Date.new(the_year, the_month, self.day)
  end

end
