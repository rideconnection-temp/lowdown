class Summary < ActiveRecord::Base
#  update_user_on_save
  point_in_time :save_updater=>true
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  has_many :summary_rows, :order=>'purpose'
  belongs_to :allocation

  accepts_nested_attributes_for :summary_rows, :reject_if => :all_blank

  attr_accessor :force_update

  before_validation :fix_period_end

  def fix_period_end
    self.period_end = self.period_start.next_month
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
    self.versioned_columns.detect {|a| __send__ "#{a}_changed?"} || self.summary_rows.detect {|a| a.create_new_version? }
  end

end
