class AddTrimetTables < ActiveRecord::Migration
  def self.up
    create_table :trimet_programs do |t|
      t.integer :trimet_identifier
      t.string  :name
      t.timestamps
    end

    create_table :trimet_providers do |t|
      t.integer :trimet_identifier
      t.string  :name
      t.timestamps
    end

    change_table :allocations do |t|
      t.references :trimet_program
      t.references :trimet_provider
    end
  end

  def self.down
    drop_table :trimet_programs
    drop_table :trimet_providers
  end
end
