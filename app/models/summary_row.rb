class SummaryRow < ActiveRecord::Base
  point_in_time
  belongs_to :summary, :primary_key=>"base_id"
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  validates_length_of :purpose, :allow_blank=>false, :minimum=>1
  validates_numericality_of :trips, :allow_blank=>false, 
end
