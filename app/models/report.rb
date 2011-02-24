class Report < ActiveRecord::Base
  validates_presence_of :name
  validates_date :start_date
  validates_date :end_date
  attr_accessor :is_new

  def allocations
    if allocation_list.nil? or allocation_list.empty?
      return []
    else
      return Allocation.where("id in ?", allocation_list.split(","))
    end
  end

  def allocations=(list)
    if list.respond_to? :values
      list = list.values
    end
    allocation_list = list.sort.map {|t| t.to_s}.join(",") 
  end

  def fields
    if field_list
      return field_list.split(",")
    else
      return []
    end
  end

  def fields=(list)
    if list.respond_to? :values
      list = list.values
    end
    field_list = list.sort.map {|t| t.to_s}.join(",") 
  end

end
