class SummaryRow < ActiveRecord::Base
  point_in_time
  belongs_to :summary
end
