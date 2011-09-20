class ChangeAllocationsAddProgram < ActiveRecord::Migration
  def self.up
    add_column :allocations, :program, :string
  end

  def self.down
    remove_column :allocations, :program
  end
end
