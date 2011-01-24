class AddUserMetadata < ActiveRecord::Migration
  def self.up
		change_table :trips do |t|
      t.integer :updated_by, :references => :users
    end
		change_table :summaries do |t|
      t.integer :updated_by, :references => :users
    end
		change_table :runs do |t|
      t.integer :updated_by, :references => :users
    end
		change_table :summary_rows do |t|
      t.integer :updated_by, :references => :users
    end
  end

  def self.down
		change_table :trips do |t|
      t.remove :updated_by
    end
		change_table :summaries do |t|
      t.remove :updated_by
    end
		change_table :runs do |t|
      t.remove :updated_by
    end
		change_table :summary_rows do |t|
      t.remove :updated_by
    end
  end
end
