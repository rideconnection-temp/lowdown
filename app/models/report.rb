class Report < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :adjustment_start_date, :presence => true, :if => :adjustment?
  validates :adjustment_end_date, :presence => true, :if => :adjustment?

  validates_date :start_date, :end_date, :adjustment_start_date, :adjustment_end_date, :allow_blank => true

  attr_accessor :is_new
  
  default_scope :order => 'position ASC'
  
  GroupBys = %w{county,quarter funding_source,quarter funding_source,funding_subsource,quarter project_number,quarter funding_source,county,provider_name,program}

  GroupMappings = {
    "agency"            => "providers.agency",
    "county"            => "allocations.county",
    "funding_source"    => "projects.funding_source",
    "funding_subsource" => "projects.funding_subsource",
    "allocation_name"   => "allocations.name",
    "program"           => "allocations.program",
    "project_name"      => "projects.name",
    "project_number"    => "projects.project_number",
    "provider_name"     => "providers.name",
    "subcontractor"     => "providers.subcontractor",
    "quarter"           => "quarter",
    "month"             => "month",
    "year"              => "year"
  }


  def self.new_from_params(params)
    report = self.new(params[:report])

    report.field_list      ||= ''
    report.allocation_list ||= ''

    report
  end

  def funding_subsource_names
    if funding_subsource_name_list.blank?
      [""]
    else
      funding_subsource_name_list.split("|")
    end
  end

  def funding_subsource_names=(list)
    if list.blank? 
      self.funding_subsource_name_list = nil
    else
      self.funding_subsource_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def program_names
    if program_name_list.blank?
      [""]
    else
      program_name_list.split("|")
    end
  end

  def program_names=(list)
    if list.blank? 
      self.program_name_list = nil
    else
      self.program_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def subcontractor_names
    if subcontractor_name_list.blank?
      [""]
    else
      subcontractor_name_list.split("|")
    end
  end

  def subcontractor_names=(list)
    if list.blank? 
      self.subcontractor_name_list = nil
    else
      self.subcontractor_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def county_names
    if county_name_list.blank?
      [""]
    else
      county_name_list.split("|")
    end
  end

  def county_names=(list)
    if list.blank? 
      self.county_name_list = nil
    else
      self.county_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def providers
    provider_list.blank? ? [] : Provider.find(provider_list.split(",").map(&:to_i))
  end

  def provider_ids
    provider_list.blank? ? [""] : provider_list.split(",").map(&:to_i)
  end

  def providers=(list)
    if list.blank?
      self.provider_list = nil
    else
      self.provider_list = list.sort.map(&:to_s).join(",")
    end
  end

  def allocations
    allocation_list.blank? ? [] : Allocation.find_all_by_id(allocation_list.split(",").map(&:to_i))
  end

  def allocation_ids
    allocation_list.blank? ? [] : allocation_list.split(",").map(&:to_i)
  end

  def allocations=(list)
    if list.blank?
      self.allocation_list = ''
    else
      self.allocation_list = list.sort.map(&:to_s).join(",")
    end
  end

  def fields
    if field_list
      return field_list.split(",")
    else
      return []
    end
  end

  def fields=(list)    
    return self.field_list = '' if list.to_s.empty?

    list = list.keys if list.respond_to?(:keys)
    self.field_list = list.sort.map(&:to_s).join(",")
  end

  def query_end_date
    Date.new(end_date.year, end_date.month, 1) + 1.months
  end
  
  def query_adjustment_end_date
    Date.new(adjustment_end_date.year, adjustment_end_date.month, 1) + 1.months if adjustment_end_date.present?
  end

end
