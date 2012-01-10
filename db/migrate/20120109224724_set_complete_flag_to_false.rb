class SetCompleteFlagToFalse < ActiveRecord::Migration
  def self.up
    Trip.update_all :complete => false
  end

  def self.down
  end
end
