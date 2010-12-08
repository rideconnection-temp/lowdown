class Allocation < ActiveRecord::Base
  has_many :trips
  belongs_to :provider
end
