class AddFundingSourcesTable < ActiveRecord::Migration
  def self.up
    create_table :funding_sources do |t|
      t.string :funding_source_name
      t.string :funding_subsource_name
      t.text :notes
      t.timestamps
    end

    rename_column :projects, :funding_source, :old_funding_source_name
    rename_column :projects, :funding_subsource, :old_funding_subsource_name
    add_column :projects, :funding_source_id, :integer
    add_column :flex_reports, :funding_source_list, :text

    Project.order(:old_funding_source_name,:old_funding_subsource_name).each do |p|
      f = FundingSource.where(:funding_source_name => p.old_funding_source_name, :funding_subsource_name => (p.old_funding_subsource_name.present? ? p.old_funding_subsource_name : nil)).first
      if f.nil?
        f = FundingSource.new
        f.funding_source_name = p.old_funding_source_name
        f.funding_subsource_name = p.old_funding_subsource_name if p.old_funding_subsource_name.present?
        f.save!
      end
      p.funding_source = f
      p.save!
    end

    FlexReport.where("funding_subsource_name_list <> ''").each do |flex|
      ids = []
      items = flex.funding_subsource_name_list.split('|') 
      puts flex.funding_subsource_name_list
      items.each do |i|
        parts = i.split(': ')
        funding_source_name = parts[0]
        funding_subsource_name = (parts.size == 2 ? parts[1] : nil)
        f = FundingSource.where(:funding_source_name => funding_source_name, :funding_subsource_name => funding_subsource_name).first
        puts "  #{funding_source_name}: #{funding_subsource_name} -- #{f.try :id}"
        ids << f.id if f.present?
      end
      flex.funding_source_list = ids.compact.sort.join(',')
      flex.save!
    end
  end

  def self.down
    drop_table :funding_sources
    remove_column :projects, :funding_source_id
    remove_column :flex_reports, :funding_source_list
    rename_column :projects, :old_funding_source_name, :funding_source
    rename_column :projects, :old_funding_subsource_name, :funding_subsource
  end
end
