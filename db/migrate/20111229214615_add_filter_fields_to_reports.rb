class AddFilterFieldsToReports < ActiveRecord::Migration
  def self.up
    change_table :reports do |t|
      t.text :funding_subsource_name_list
      t.text :provider_list
      t.text :program_name_list
      t.text :county_name_list
    end
  end

  def self.down
    change_table :reports do |t|
      t.remove :funding_subsource_name_list
      t.remove :provider_list
      t.remove :program_name_list
      t.remove :county_name_list
    end
  end
end
