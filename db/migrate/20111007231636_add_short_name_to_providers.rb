class AddShortNameToProviders < ActiveRecord::Migration
  def self.up
    add_column :providers, :short_name, :string, :limit=>10
  end

  def self.down
    remove_column :providers, :short_name
  end
end
