class RemoveBranchAndAgencyFromProviders < ActiveRecord::Migration
  def self.up
    remove_column :providers, :branch, :agency
  end

  def self.down
    change_table :providers do |t|
      t.string   "agency",        :limit => 50
      t.string   "branch",        :limit => 50
    end
  end
end
