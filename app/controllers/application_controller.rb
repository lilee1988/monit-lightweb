require 'authenticated_system'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticatedSystem
  before_filter :login_required

  private

  def filter_params options = {}, update = {}
    options = options.dup
    options.delete :sort
    options.delete :page
    options.delete :action
    options.delete :controller
    options.update update
    options
  end

  def parse_date_range date = nil
    now = Time.now
    #now = Time.parse("2010-11-23 14:30") if RAILS_ENV == 'development' #For test
    if date == 'today'
      start = now.at_beginning_of_day
      finish = now
      human = I18n.t(date)
    elsif date == 'yesterday'
      start = now.at_beginning_of_day - 1.day
      finish = now.at_beginning_of_day
      human = I18n.t(date)
    elsif date == 'thisweek'
      start = now.at_beginning_of_week
      finish = now
      human = I18n.t(date)
    elsif date == 'last7days'
      start = now - 7.days
      finish = now
      human = I18n.t(date)
    elsif date == 'thismonth'
      start = now.at_beginning_of_month
      finish = now
      human = I18n.t(date)
    elsif date == 'last30days'
      start = now - 30.days
      finish = now
      human = I18n.t(date)
    elsif date.blank?
      date = "last24hours"
    else
      da = date.split(",")
      begin
        start = Date.parse(da[0])
        if da[1].blank?
          finish = start
        else
          finish = Date.parse(da[1])
        end
        start, finish = finish, start if start > finish
        if start == finish
          human = start.to_s
          date = start.to_s
        else
          human = "#{start.to_s}到#{finish.to_s}"
          date = "#{start.to_s},#{finish.to_s}"
        end
        start = start.to_time
        finish = (finish + 1).to_time
      rescue ArgumentError
        date = "last24hours"
      end
    end
    if date == "last24hours"
      start = now - 1.day
      finish = now
      human = I18n.t(date)
    end
    num = (finish - start).to_i
    {:start => start, :finish => finish,:human => human, :param => date, :n => num}
  end

end
