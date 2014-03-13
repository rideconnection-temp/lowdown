class RemoveRaceTable < ActiveRecord::Migration
  def up
    drop_table "races" 
  end

  def down
    create_table "races" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
