class AddCreatedAtToSummaries < ActiveRecord::Migration
  def self.up
    add_column :summaries, :first_version_created_at, :datetime
  end

  def self.down
    remove_column :summaries, :first_version_created_at
  end
end
