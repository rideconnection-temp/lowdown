class DeleteTrimetReportGroups < ActiveRecord::Migration
  def change
    drop_table "trimet_report_groups" do
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    remove_column :allocations, :trimet_report_group_id, :integer
  end
end
