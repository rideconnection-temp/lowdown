class UsersController < Devise::SessionsController
  before_filter :require_admin_user, only: [:index, :show_create, :create_user, :deactivate, :update]

  require 'new_user_mailer'

  def new
    #hooked up to sign_in
    if User.count == 0
      return redirect_to action: :show_init
    end
  end

  def show_init
    #create initial user
    if User.count > 0
      return redirect_to action: :new
    end
    @user = User.new
  end

  def init
    if User.count > 0
      return redirect_to action: :new
    end
    @user = User.new user_params
    @user.level = 100
    @user.save!

    flash[:notice] = "OK, now sign in"
    redirect_to action: :new
  end

  def show_create
    @user = User.new
  end

  def show_change_password
    @user = current_user
  end

  def change_password
    if current_user.update_attributes(password: params[:password], password_confirmation: params[:password_confirmation])
      flash[:notice] = "Password changed"
      redirect_to root_url
    else
      flash.now[:alert] = "Error updating password"
      render action: :show_change_password
    end
  end

  def create_user
    if !current_user.is_admin
      flash[:alert] = "You don't have permission to create users"
      return redirect_to root_path
    end
    password = SecureRandom.base64(6)
    params[:user][:password] = params[:user][:password_confirmation] = password
    @user = User.new(user_params)
    @user.level = params[:user][:level]
    @user.save!
    NewUserMailer.new_user_email(@user, password).deliver
    flash[:notice] = "User #{@user.email} created"
    redirect_to action: :index, controller: :users
  end

  
  def update
    @user = User.find(params[:id])
    if @user.update_attributes!(user_params)
      flash[:notice] = "User %s updated" % @user.email
      redirect_to action: :index
    else
      flash.now[:alert] = "Error: " + @user.errors
      render action: :index      
    end
  end
  

  def sign_out
    scope = Devise::Mapping.find_scope!(current_user)
    current_user = nil
    warden.logout(scope)

    return redirect_to root_url
  end

  def index
    @users = User.order(:active,:level,:email)
  end
  
private

  def user_params
    params.require(:email).permit(:password, :password_confirmation, :level, :active)
  end
end
