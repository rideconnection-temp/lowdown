class FixTripsMonthlyHouseholdIncomeField < ActiveRecord::Migration
  def self.up
		rename_column :customers, :monthy_household_income, :monthly_household_income
  end

  def self.down
		rename_column :customers, :monthly_household_income, :monthy_household_income
  end
end
