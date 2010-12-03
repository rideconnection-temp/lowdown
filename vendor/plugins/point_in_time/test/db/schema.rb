ActiveRecord::Schema.define(:version=>0) do
  
  create_table :authors, :id=>false, :force=>true do |t|
    t.column :id, :string, :limit=>36, :primary => true
    t.column :base_id, :string, :limit=>36
    t.column :valid_start, :datetime
    t.column :valid_end, :datetime
    t.column :first_name, :string, :limit=>255
    t.column :last_name, :string, :limit=>255
  end
    
  create_table :pages, :id=>false, :force=>true do |t|
    t.column :id, :string, :limit=>36, :primary => true
    t.column :base_id, :string, :limit=>36
    t.column :valid_start, :datetime
    t.column :valid_end, :datetime
    t.column :type, :string
    t.column :title, :string, :limit=>255
    t.column :body, :text
    t.column :creator_id, :string, :limit=>36
    t.column :author_id, :string, :limit=>36
  end
  
end
