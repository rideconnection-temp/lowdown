class UsersController < ApplicationController
  require 'new_user_mailer'
  protect_from_forgery

  before_filter :require_user, :only=>[:show_change_password, :change_password]
  before_filter :require_admin_user, :except=>[:show_change_password, :change_password]

  def show_change_password
    @user = current_user
  end

  def change_password
    if params[:user][:password] != params[:user][:password_confirmation]
      flash[:notice] = "Passwords do not match"
      return redirect_to :action=>:show_change_password
    end
    current_user.password = params[:user][:password]
    current_user.password_confirmation = params[:user][:password_confirmation]
    current_user.login_count += 1
    current_user.save!
    flash[:notice] = "Password changed"
    return redirect_to "/"
  end

  def create
    password = ActiveSupport::SecureRandom.base64(6)
    params[:user][:password] = params[:user][:password_confirmation] = password
    @user = User.create(params[:user])
    NewUserMailer.new_user_email(@user, password).deliver
    flash[:notice] = "User #{@user.name} created"
    redirect_to :action=>:index
  end

  def index
    @users = User.all
  end

  def show_create
    @user = User.new
  end


  def show
    @user = User.find(params[:id])
  end

end
