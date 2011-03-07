class AddSummary < ActiveRecord::Migration
  def self.up

    create_table :allocations do |t|
      t.string :name
    end

    create_table :summaries, :id=>false do |t|
      t.string :id, :limit => 36, :null => false, :unique => true
      t.string :base_id, :limit => 36, :references=>nil
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

    execute "alter table summaries add primary key(id)"


    create_table :summary_rows, :id=>false do |t|
      t.string :id, :limit => 36, :null => false, :unique => true
      t.string :base_id, :limit => 36, :references=>nil
      t.datetime :valid_start
      t.datetime :valid_end

      t.string :summary_id, :references=>:summaries
      t.string :purpose
      t.integer :trips
      t.boolean :in_district
      t.references :allocations
    end

  end

  def self.down
    drop_table :allocations
    drop_table :summaries
    drop_table :summary_rows
  end
end
