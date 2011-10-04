class Report < ActiveRecord::Base
  validates :name, :presence => true
  validates :adjustment_start_date, :presence => true, :if => :adjustment?
  validates :adjustment_end_date, :presence => true, :if => :adjustment?

  validates_date :start_date, :end_date, :adjustment_start_date, :adjustment_end_date, :allow_blank => true

  attr_accessor :is_new
  
  default_scope :order => 'position ASC'
  
  GroupBys = %w{county,quarter funding_source,quarter funding_source,funding_subsource,quarter project_number,quarter county,agency funding_source,county,agency,project_name funding_source,county,agency funding_source,agency project_name,agency agency,county,project_name}

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

  def allocations
    if allocation_list.nil? or allocation_list.empty?
      return []
    else
      return Allocation.find(allocation_list.split(",").map(&:to_i))
    end
  end

  def allocations=(list)
    if list.to_s.empty?
      self.allocation_list = ''
      return
    end
    if list.respond_to? :keys
      list = list.keys
    end
    self.allocation_list = list.sort.map(&:to_s).join(",")
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
