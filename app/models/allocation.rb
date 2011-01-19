class Allocation < ActiveRecord::Base
  has_many :trips
  belongs_to :provider
  belongs_to :project

  acts_as_taggable
end
