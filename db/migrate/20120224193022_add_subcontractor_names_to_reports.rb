class AddSubcontractorNamesToReports < ActiveRecord::Migration
  def self.up
    change_table :reports do |t|
      t.text :subcontractor_name_list
    end
  end

  def self.down
    change_table :reports do |t|
      t.text :subcontractor_name_list
    end
  end
end
