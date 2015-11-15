class AddServiceTypeToAllocations < ActiveRecord::Migration
  def change
    create_table(:service_types) do |t|
      t.string :name
      t.timestamps
    end

    add_column :allocations, :service_type_id, :integer
    add_column :flex_reports, :service_type_list, :text
  end
end
