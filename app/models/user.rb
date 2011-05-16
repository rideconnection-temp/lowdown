class User < ActiveRecord::Base
  model_stamper
  validates_confirmation_of :password
  validates_uniqueness_of :email

  belongs_to :current_provider, :class_name=>"Provider", :foreign_key => :current_provider_id

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :level, :active

  def is_admin
    return level == 100
  end

  def active?
    !!active
  end
end
