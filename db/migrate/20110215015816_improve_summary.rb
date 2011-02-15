class ImproveSummary < ActiveRecord::Migration
  def self.up
    change_table :summaries do |t|
      t.remove :compliments
      t.remove :complaints
      t.remove :prepared_by
      t.remove :report_prepared
      t.remove :provider_id
    end

    change_table :summary_rows do |t|
      t.remove :in_district
      t.rename :trips, :in_district_trips
      t.integer :out_of_district_trips
    end
  end

  def self.down
    change_table :summaries do |t|
      t.integer :compliments
      t.integer :complaints
      t.string :prepared_by
      t.date :report_prepared
      t.integer :provider_id
    end

    change_table :summary_rows do |t|
      t.boolean :in_district
      t.rename :in_district_trips, :trips
      t.remove :out_of_district_trips
    end
  end
end
