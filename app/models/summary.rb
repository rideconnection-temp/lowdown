class Summary < ActiveRecord::Base
  point_in_time
  has_many :summary_rows, :order=>'purpose'
  belongs_to :provider

  accepts_nested_attributes_for :summary_rows, :allow_destroy => true, :reject_if => :all_blank

end
