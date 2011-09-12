class Report < ActiveRecord::Base
  validates_presence_of :name
  validates_date :start_date
  validates_date :end_date
  attr_accessor :is_new
  
  GroupBys = %w{county,quarter funding_source,quarter funding_source,funding_subsource,quarter project_number,quarter county,agency funding_source,county,agency,project_name funding_source,county,agency funding_source,agency project_name,agency agency,county,project_name}

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
    Date.new end_date.year, end_date.month + 1, 1
  end

end
