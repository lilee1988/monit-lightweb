# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem
  skip_before_filter :login_required
  layout "entry" ,:only=>[:new, :create]

  # render new.rhtml
  def new
    current_user.update_attribute(:status, 2) if current_user #Login for invate
    #redirect_to logged_in? ? root_path : "http://www.chinaccnet.com/login.php?goto_page=http://www.chinaccnet.com/monit.php" and return
    redirect_to "http://www.chinaccnet.com/login.php?goto_page=http://www.chinaccnet.com/monit.php" unless logged_in?
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      redirect_back_or_default('/', :notice => "Logged in successfully")
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    redirect_back_or_default('/', :notice => "You have been logged out.")
  end

  protected
  # Track failed login attempts
  def note_failed_signin
    #flash.now[:error] = "Couldn't log you in as '#{params[:login]}'"
    @error = "用户名或密码错误"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
