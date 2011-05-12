class Report < ActiveRecord::Base
  validates_presence_of :name
  validates_date :start_date
  validates_date :end_date
  attr_accessor :is_new

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
    if list.to_s.empty?
      self.field_list = ''
      return
    end
    if list.respond_to? :keys
      list = list.keys
    end
    self.field_list = list.sort.map(&:to_s).join(",")
  end

end
