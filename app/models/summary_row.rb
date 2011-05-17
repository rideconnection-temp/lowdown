class SummaryRow < ActiveRecord::Base
  belongs_to :summary, :primary_key=>"base_id"
  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by

  validates_length_of :purpose, :allow_blank=>false, :minimum=>1
  validates_numericality_of :in_district_trips, :allow_blank=>false
  validates_numericality_of :out_of_district_trips, :allow_blank=>false

  def created_by
    return first_version.updated_by
  end
end
