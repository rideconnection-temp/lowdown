class CreateReportCategory < ActiveRecord::Migration
  def self.up
    create_table :report_categories do |t|
      t.string :name
      t.timestamps
    end
    add_column :flex_reports, :report_category_id, :integer
  end

  def self.down
    drop_table :report_categories do |t|
      t.string :name
      t.timestamps
    end
    remove_column :flex_reports, :report_category_id
  end
end
