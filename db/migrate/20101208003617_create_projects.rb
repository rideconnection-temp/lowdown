class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :name
      t.string :funding_source
      t.string :funding_subsource
      t.string :project_number

      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end
