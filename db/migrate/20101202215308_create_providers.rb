class CreateProviders < ActiveRecord::Migration
  def self.up
    create_table :providers do |t|
      t.string :name, :limit => 50
      t.string :provider_type, :limit => 15
      t.string :agency, :limit => 50
      t.string :branch, :limit => 50
      t.string :subcontractor, :limit => 50
      t.string :routematch_id, :limit => 10, :references=>nil

      t.timestamps

			
    end
  end

  def self.down
    drop_table :providers
  end
end
