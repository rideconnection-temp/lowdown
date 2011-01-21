class Summary < ActiveRecord::Base
#  update_user_on_save
  point_in_time :save_updater=>true
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  has_many :summary_rows, :order=>'purpose'
  belongs_to :provider

  accepts_nested_attributes_for :summary_rows, :allow_destroy => true, :reject_if => :all_blank

end
