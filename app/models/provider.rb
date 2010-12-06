class Provider < ActiveRecord::Base
	has_many :trips
  has_many :summaries
end
