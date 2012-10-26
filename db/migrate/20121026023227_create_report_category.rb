class CreateReportCategory < ActiveRecord::Migration
  def self.up
    create_table :report_categories do |t|
      t.string :name
      t.timestamps
    end
    change_table :flex_reports do |t|
      t.references :report_category
    end
  end

  def self.down
    drop_table :report_categories do |t|
      t.string :name
      t.timestamps
    end
    remove_column :flex_reports, :report_category_id
  end
end
