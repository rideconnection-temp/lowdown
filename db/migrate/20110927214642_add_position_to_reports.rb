class AddPositionToReports < ActiveRecord::Migration
  def self.up
    add_column :reports, :position, :integer
  end

  def self.down
    remove_column :reports, :position
  end
end
