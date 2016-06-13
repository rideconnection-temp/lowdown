class User < ActiveRecord::Base
  model_stamper
  validates_confirmation_of :password
  validates_uniqueness_of :email

  belongs_to :current_provider, class_name: "Provider", foreign_key: :current_provider_id

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :recoverable, :trackable, :validatable

  def is_admin
    return level == 100
  end

  def active?
    !!active
  end
end
