class CreateMobilities < ActiveRecord::Migration
  def self.up
    create_table :mobilities do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :mobilities
  end
end
