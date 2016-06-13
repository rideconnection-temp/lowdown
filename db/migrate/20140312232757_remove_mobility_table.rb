class RemoveMobilityTable < ActiveRecord::Migration
  def up
    drop_table "mobilities"
  end

  def down
    create_table "mobilities" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
