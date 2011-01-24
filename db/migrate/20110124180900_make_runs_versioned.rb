class MakeRunsVersioned < ActiveRecord::Migration
  def self.up

    drop_table :runs

    create_table :runs, :id=>false do |t|
      t.string :id, :limit => 36, :null => false, :unique => true
      t.string :base_id, :limit => 36, :references=>nil
      t.datetime :valid_start
      t.datetime :valid_end

      t.date     :date
      t.string   :name
      t.integer  :routematch_id, :references=>nil
      t.datetime :start_at
      t.datetime :end_at
      t.integer  :odometer_start
      t.integer  :odometer_end
      t.integer  :escort_count
      t.integer  :trip_import_id
      t.integer  :updated_by
    end
    change_column :trips, :run_id, :string, :limit=>36, :references=>nil
      
  end

  def self.down
    drop_table :runs
    create_table :runs do |t|
      t.date     :date
      t.timestamps
      t.string   :name
      t.integer  :routematch_id, :references=>nil
      t.datetime :start_at
      t.datetime :end_at
      t.integer  :odometer_start
      t.integer  :odometer_end
      t.integer  :escort_count
      t.integer  :trip_import_id
      t.integer  :updated_by    
    end

    change_column :trips, :run_id, :integer
  end
end
