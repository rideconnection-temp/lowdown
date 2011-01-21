class RenameUserCreator < ActiveRecord::Migration

  def self.up
    rename_column :users, :creator, :created_by
  end

  def self.down
    rename_column :users, :created_by, :creator
  end

end
