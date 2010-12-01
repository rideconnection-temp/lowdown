class UsersController < ApplicationController
  protect_from_forgery

  before_filter :require_user, :except => [:login, :create]

  def create
    User.create(@params)

  end

  def show
  end

end
