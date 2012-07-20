class Summary < ActiveRecord::Base
#  update_user_on_save
  class << self
    def date_range(start_date, after_end_date)
      start_date = start_date.to_date
      after_end_date = after_end_date.to_date
      where("period_start >= ? and period_end < ?",start_date,after_end_date)
    end
  end

  point_in_time :save_updater=>true
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  has_many :summary_rows, :order=>'purpose'
  belongs_to :allocation

  accepts_nested_attributes_for :summary_rows, :reject_if => :all_blank

  attr_accessor :force_update, :do_not_version

  before_validation :fix_period_end

  TripAttrs = [:total_miles,:turn_downs,:unduplicated_riders,:driver_hours_paid,:driver_hours_volunteer,:escort_hours_volunteer]
  
  validates :allocation_id, :presence => true
  validates_numericality_of :administrative_hours_volunteer, :unless => Proc.new {|rec| rec.allocation.try(:cost_collection_method) == 'none'}
  validates_numericality_of :funds,                          :unless => Proc.new {|rec| rec.allocation.try(:cost_collection_method) == 'none'}
  validates_numericality_of :donations,                      :unless => Proc.new {|rec| rec.allocation.try(:cost_collection_method) == 'none'}
  validates_numericality_of :agency_other,                   :unless => Proc.new {|rec| rec.allocation.try(:cost_collection_method) == 'none'}
  validates_numericality_of :administrative, :if => Proc.new {|rec| rec.allocation.try(:admin_ops_data) == 'Required'} 
  validates_numericality_of :operations,     :if => Proc.new {|rec| rec.allocation.try(:admin_ops_data) == 'Required'} 
  validates_numericality_of :vehicle_maint,  :if => Proc.new {|rec| rec.allocation.try(:vehicle_maint_data) == 'Required'} 
  validates_size_of :administrative, :is => 0, :allow_nil => true, :if => Proc.new {|rec| rec.allocation.try(:admin_ops_data) == 'Prohibited'}, :wrong_length => "should be blank"
  validates_size_of :operations, :is => 0, :allow_nil => true, :if => Proc.new {|rec| rec.allocation.try(:admin_ops_data) == 'Prohibited'}, :wrong_length => "should be blank"
  validates_size_of :vehicle_maint, :is => 0, :allow_nil => true, :if => Proc.new {|rec| rec.allocation.try(:vehicle_maint_data) == 'Prohibited'}, :wrong_length => "should be blank"
  validates_date :period_start, 
      :on_or_after => lambda{|r| r.allocation.try(:activated_on)}, 
      :on_or_after_message => "is not valid for this allocation", 
      :before => lambda{|r| r.allocation.try(:inactivated_on)},
      :before_message => "is not valid for this allocation"

  validate do |record|
    if Summary.where("base_id <> COALESCE(?,0)",record.base_id).where(:period_start => record.period_start,:allocation_id => record.allocation_id).exists?
      record.errors.add :allocation_id, "already in use in another summary for this month"
    end
    record.summary_rows.each do |row|
      if record.allocation.try(:trip_collection_method) == 'summary_rows' 
        unless row.in_district_trips.is_a? Numeric
          row.errors.add :in_district_trips, "is not a number" 
          record.errors.add_to_base "#{row.purpose} in district trips is not a number" 
        end
        unless row.out_of_district_trips.is_a? Numeric
          row.errors.add :out_of_district_trips, "is not a number" 
          record.errors.add_to_base "#{row.purpose} out of district trips is not a number" 
        end
      else
        unless row.in_district_trips.blank?
          row.errors.add :in_district_trips, "should be blank" 
          record.errors.add_to_base "#{row.purpose} in district trips should be blank" 
        end
        unless row.out_of_district_trips.blank?
          row.errors.add :out_of_district_trips, "should be blank" 
          record.errors.add_to_base "#{row.purpose} out of district trips should be blank" 
        end
      end
    end
  end

  validates_each *TripAttrs do |record, attr, value|
    if record.allocation.try(:trip_collection_method) == 'summary_rows' 
      record.errors.add attr, "is not a number" unless value.is_a? Numeric
    else
      record.errors.add attr, "should be blank." unless value.blank?
    end
  end

  scope :valid_range, lambda{|start_date, end_date| where("summaries.valid_start <= ? and summaries.valid_end > ?",start_date,end_date) } 
  scope :data_entry_complete, where(:complete => true)
  scope :data_entry_not_complete, where(:complete => false)
  scope :for_date_range, lambda {|start_date, end_date| where("summaries.period_start >= ? AND summaries.period_start < ?", start_date, end_date) }
  scope :for_allocation, lambda {|allocation| where(:allocation_id => allocation.id) }
  scope :for_provider, lambda {|provider_id| where("summaries.allocation_id IN (SELECT id FROM allocations WHERE provider_id = ?)",provider_id)}
  scope :with_no_provider, where("summaries.allocation_id IN (SELECT id FROM allocations WHERE provider_id IS NULL)")
  scope :for_reporting_agency, lambda {|provider_id| where("summaries.allocation_id IN (SELECT id FROM allocations WHERE reporting_agency_id = ?)",provider_id)}
  scope :with_no_reporting_agency, where("summaries.allocation_id IN (SELECT id FROM allocations WHERE reporting_agency_id IS NULL)")

  def created_by
    return first_version.updater
  end

  def updater
    return User.find(updated_by)
  end

  def provider
    return allocation.provider
  end

  def in_district_trips
    summary_rows.inject(0) {|sum,r| sum + (r.in_district_trips || 0)}
  end

  def out_of_district_trips
    summary_rows.inject(0) {|sum,r| sum + (r.out_of_district_trips || 0)}
  end

  def trips
    self.summary_rows.inject(0) {|sum,r| sum + (r.out_of_district_trips || 0) + (r.in_district_trips || 0)}
  end

  def total_cost
    (agency_other || 0) + (funds || 0) + (donations || 0) + (administrative || 0) + (operations || 0) + (vehicle_maint || 0)
  end

  def create_new_version?
    return false if do_not_version?
    
    self.versioned_columns.detect {|a| __send__ "#{a}_changed?"} || self.summary_rows.detect {|a| a.changed? }
  end

  def do_not_version?
    do_not_version == true || do_not_version.to_i == 1 || !complete || !complete_was
  end

private
  def fix_period_end
    self.period_end = self.period_start.next_month - 1.day
  end



end
