class CopyExistingOverridesToExistingOverrides < ActiveRecord::Migration
  def self.up
    Trip.update_all "original_override = override"
  end

  def self.down
    Trip.update_all "original_override = NULL"
  end
end
