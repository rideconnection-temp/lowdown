class TrimetProvider < ActiveRecord::Base
  has_many :allocations, -> { order :name }
  
  validates :name, presence: true, uniqueness: true
  validates :trimet_identifier, presence: true, uniqueness: true

  scope :default_order, -> { order :name }

  def name_and_identifier
    "#{name} (#{trimet_identifier})"
  end
end
