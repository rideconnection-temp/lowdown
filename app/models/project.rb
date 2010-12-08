class Project < ActiveRecord::Base
  has_many :allocations
end
