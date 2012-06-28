class CreateOverrides < ActiveRecord::Migration
  def self.up
    create_table :overrides do |t|
      t.string :name

      t.timestamps
    end

    add_column :allocations, :override_id, :integer

    Allocation.order(:routematch_override).each do |allocation|
      unless allocation.routematch_override.blank?
        o = Override.find_or_create_by_name allocation.routematch_override 
        allocation.override_id = o.id
        allocation.save!
      end
    end
  end

  def self.down
    drop_table :overrides
    remove_column :allocations, :override_id 
  end
end
