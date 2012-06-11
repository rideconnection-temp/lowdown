class CreateTrimetReportGroups < ActiveRecord::Migration
  def self.up
    create_table :trimet_report_groups do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :trimet_report_groups
  end
end
