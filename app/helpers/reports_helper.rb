module ReportsHelper
  
  def short_group_name(row,group_fields)
    return unless group_fields.present?
    this_row = get_row(row) 
    short_attr_name = "short_#{group_fields[0]}"
    group = this_row.send(group_fields[0])
    this_row.respond_to?(short_attr_name) && this_row.send(short_attr_name) ? this_row.send(short_attr_name) : group
  end

  def group_name(row,group_fields)
    get_row(row).send(group_fields[0]) 
  end

  def get_row(e)
    if e.instance_of? Hash
      get_row e.first[1]
    else
      e
    end
  end

end
