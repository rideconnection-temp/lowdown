class AddCreatedAtToSummaries < ActiveRecord::Migration
  def self.up
    add_column :summaries, :first_version_created_at, :datetime
    execute <<-SQL
      UPDATE summaries
      SET first_version_created_at = (
              SELECT MIN(valid_start) 
              FROM summaries as s
              WHERE s.base_id = summaries.base_id)
    SQL
  end

  def self.down
    remove_column :summaries, :first_version_created_at
  end
end
