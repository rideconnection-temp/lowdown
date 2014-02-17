class AddNotesToTriMetPrograms < ActiveRecord::Migration
  def self.up
    change_table :trimet_programs do |t|
      t.text :notes
    end
  end

  def self.down
    change_table :trimet_programs do |t|
      t.remove :notes
    end
  end
end
