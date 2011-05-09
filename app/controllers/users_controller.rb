class UsersController < Devise::SessionsController
  require 'new_user_mailer'

  def new
    print "HERE\n"
    #hooked up to sign_in
    if User.count == 0
      print "redirect to show_init\n"
      return redirect_to :action=>:show_init
    end
  end


  def show_init
    #create initial user
    if User.count > 0
      print "redirect to new\n"
      return redirect_to :action=>:new
    end
    @user = User.new
  end

  def init
    if User.count > 0
      return redirect_to :action=>:new
    end
    @user = User.new params[:user]
    @user.level = 100
    @user.save!

    flash[:notice] = "OK, now sign in"
    redirect_to :action=>:new
  end

  def show_create
    @user = User.new
  end

  def create_user
    if !current_user.is_admin
      flash[:alert] = "You don't have permission to create users"
      return redirect_to root_path
    end
    password = ActiveSupport::SecureRandom.base64(6)
    params[:user][:password] = params[:user][:password_confirmation] = password
    @user = User.new(params[:user])
    @user.level = params[:user][:level]
    @user.save!
    NewUserMailer.new_user_email(@user, password).deliver
    flash[:notice] = "User #{@user.email} created"
    redirect_to :action=>:index, :controller=>:users
  end

  def sign_out
    scope = Devise::Mapping.find_scope!(current_user)
    current_user = nil
    warden.logout(scope)

    return redirect_to "/"
  end

  def index
    @users = User.all
  end
end
