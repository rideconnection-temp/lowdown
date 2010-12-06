class Summary < ActiveRecord::Base
  point_in_time
  has_many :summary_row
  belongs_to :provider
end
