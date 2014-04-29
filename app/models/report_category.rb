class ReportCategory < ActiveRecord::Base
  has_many :flex_reports, -> { order :name }
  
  validates :name, :presence => true, :uniqueness => true

  scope :default_order, -> { order :name }
end
