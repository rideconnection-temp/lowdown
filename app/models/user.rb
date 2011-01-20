class User < ActiveRecord::Base
  validates :name,  :presence => true
  validates :email, :presence => true, :uniqueness => true
  validates_presence_of :password
  validates_confirmation_of :password

  
  acts_as_authentic do |c|
    c.login_field = :email
    c.validate_login_field = false
  end
end
