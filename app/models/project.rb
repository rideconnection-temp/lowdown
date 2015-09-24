class Project < ActiveRecord::Base
  has_many :allocations
  belongs_to :funding_source
  
  validates :name, presence: true, uniqueness: true

  scope :default_order, -> { order :name }

  def number_and_name
    if project_number.present?
      "#{project_number} - #{name}"
    else
      name
    end
  end
end
