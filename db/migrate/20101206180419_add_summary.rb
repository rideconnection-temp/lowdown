class AddSummary < ActiveRecord::Migration
  def self.up

    create_table :allocation do |t|
      t.string :name
    end

    create_table :summary, :id=>false do |t|
      t.string :id, :limit => 36, :null => false, :primary_key => true
      t.string :base_id, :limit => 36
      t.datetime :valid_start
      t.datetime :valid_end

      t.date :period_start
      t.date :period_end
      t.integer :total_miles
      t.integer :driver_hours_paid
      t.integer :driver_hours_volunteer
      t.integer :escort_hours_volunteer
      t.integer :administrative_hours_volunteer
      t.integer :unduplicated_riders
      t.integer :compliments
      t.integer :complaints
      t.references :provider
      t.string :prepared_by #TODO: should this be a reference?
      t.date :report_prepared
    end

    create_table :summary_row, :id=>false do |t|
      t.string :id, :limit => 36, :null => false, :primary_key => true
      t.string :base_id, :limit => 36
      t.datetime :valid_start
      t.datetime :valid_end

      t.references :summary
      t.string :purpose
      t.integer :trips
      t.boolean :in_district
      t.references :allocation
    end

  end

  def self.down
    drop_table :allocation
    drop_table :summary
    drop_table :summary_row
  end
end
