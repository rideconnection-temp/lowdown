class Mobility < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true 
end
