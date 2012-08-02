class SummaryRow < ActiveRecord::Base
  belongs_to :summary
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  validates_length_of :purpose, :allow_blank=>false, :minimum=>1
  validates_numericality_of :in_district_trips, :allow_blank=>true
  validates_numericality_of :out_of_district_trips, :allow_blank=>true

  def created_by
    return first_version.updated_by
  end
end
