class AddPremiumBillingMethodToAllocations < ActiveRecord::Migration
  def change
    change_table :allocations do |t|
      t.string :premium_billing_method, limit: 255
    end
  end
end
