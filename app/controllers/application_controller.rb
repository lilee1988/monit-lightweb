require 'authenticated_system'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticatedSystem
  before_filter :login_required
  before_filter :limit_for_test
  def limit_for_test
    redirect_to root_url if RAILS_ENV == "production"
  end

end
