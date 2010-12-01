class User < ActiveRecord::Base
  validates :name,  :presence => true
  validates :email, :presence => true, :uniqueness => true
  
  acts_as_authentic do |c|
    c.login_field = :email
    c.validate_login_field = false
  end
end
