class UserSessionController < ActionController::Base

  def new
    if User.count == 0
      return redirect_to :action=>:show_init
    end
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_to '/'
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_to new_user_session_url
  end

  def show_init
    if User.count > 0
      return render_text "already initialized"
    end
    @user = User.new
  end

  def init
    if User.count > 0
      return render_text "already initialized"
    end
    params[:user][:level] = 100
    @user = User.create(params[:user])
    @user.login_count = 2 #to prevent the automatic password changer from kicking in
    @user.save
    @user_session = UserSession.new(params[:user])
    @user_session.save
    redirect_to '/'
  end


end
