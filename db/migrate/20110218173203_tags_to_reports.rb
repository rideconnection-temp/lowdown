class TagsToReports < ActiveRecord::Migration
  def self.up
    drop_table :taggings
    drop_table :tags

    create_table :reports do |t|
      t.string :name
      t.date :start_date
      t.date :end_date
      t.string :group_by
      t.string :allocation_list
      t.string :field_list
      t.boolean :pending
      t.boolean :adjustment
    end
  end

  def self.down
    create_table :tags do |t|
      t.string :name
    end

    create_table :taggings do |t|
      t.references :tag

      t.references :taggable, :polymorphic => true, :references=>nil
      t.references :tagger, :polymorphic => true, :references=>nil

      t.string :context

      t.datetime :created_at
    end

    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
