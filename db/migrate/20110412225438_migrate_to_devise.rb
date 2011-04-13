class MigrateToDevise < ActiveRecord::Migration
  def self.up
    drop_table :users
    create_table :users do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable
      t.timestamps
      t.integer  "level"
    end
    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
  end

  def self.down
  end
end
