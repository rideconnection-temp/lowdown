class Summary < ActiveRecord::Base
#  update_user_on_save
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
  validates :administrative_hours_volunteer, :numericality => true 
  validates :funds, :numericality => true
  validates :donations, :numericality => true
  validates :agency_other, :numericality => true

  validate do |record|
    record.summary_rows.each do |row|
      if record.allocation.try(:trip_collection_method) == 'summary_rows' 
        if row.in_district_trips.blank?
          row.errors.add :in_district_trips, "cannot be blank." 
          record.errors.add_to_base "\"#{row.purpose}\" in district trips cannot be blank" 
        end
        if row.out_of_district_trips.blank?
          row.errors.add :out_of_district_trips, "cannot be blank." 
          record.errors.add_to_base "\"#{row.purpose}\" out of district trips cannot be blank" 
        end
      else
        unless row.in_district_trips.blank?
          row.errors.add :in_district_trips, "must be blank." 
          record.errors.add_to_base "\"#{row.purpose}\" in district trips must be blank" 
        end
        unless row.out_of_district_trips.blank?
          row.errors.add :out_of_district_trips, "must be blank." 
          record.errors.add_to_base "\"#{row.purpose}\" out of district trips must be blank" 
        end
      end
    end
  end

  validates_each *TripAttrs do |record, attr, value|
    if record.allocation.try(:trip_collection_method) == 'summary_rows' 
      record.errors.add attr, "cannot be blank." if value.blank?
    else
      record.errors.add attr, "must be left blank." unless value.blank?
    end
  end

  def fix_period_end
    self.period_end = self.period_start.next_month - 1.day
  end

  def created_by
    return first_version.updater
  end

  def updater
    return User.find(updated_by)
  end

  def provider
    return allocation.provider
  end

  def create_new_version?
    return false if do_not_version?
    
    self.versioned_columns.detect {|a| __send__ "#{a}_changed?"} || self.summary_rows.detect {|a| a.changed? }
  end

  def in_district_trips
    summary_rows.inject(0) {|sum,r| sum + r.in_district_trips}
  end

  def out_of_district_trips
    summary_rows.inject(0) {|sum,r| sum + r.out_of_district_trips}
  end

  def trips
    self.summary_rows.inject(0) {|sum,r| sum + r.out_of_district_trips + r.in_district_trips }
  end

  def do_not_version?
    do_not_version == true || do_not_version.to_i == 1
  end
end
