class CreatePrograms < ActiveRecord::Migration
  def self.up
    create_table :programs do |t|
      t.string :name
      t.timestamps
    end

    add_column :allocations, :program_id, :integer
    rename_column :allocations, :program, :program_name

    program_names = Allocation.select('DISTINCT program_name').where("COALESCE(program_name,'') <> ''").map {|x| x.program_name }.sort 

    program_names.each {|pn| Program.create!(:name => pn) }

    Allocation.where("COALESCE(program_name,'') <> ''").each do |a|
      a.program_id = Program.where(:name => a.program_name).first.id 
      a.save!
    end

    add_column :flex_reports, :program_list, :text

    FlexReport.where('program_name_list IS NOT NULL').each do |f|
      program_ids = []
      flex_report_program_names = f.program_name_list.split('|')
      flex_report_program_names.each do |name|
        program_id = Program.where(:name => name).first.try(:id)
        program_ids << program_id unless program_id.blank?
      end
      f.program_list = program_ids.sort.join(',')
      f.save!
    end

  end

  def self.down
    drop_table :programs
    remove_column :allocations, :program_id
    remove_column :flex_reports, :program_list
    rename_column :allocations, :program_name, :program
  end
end
