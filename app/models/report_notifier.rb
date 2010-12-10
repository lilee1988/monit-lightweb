class ReportNotifier < ActionMailer::Base

  layout "email"

  def daily(user)
    now = Time.now
    #now = Time.parse("2010-7-13 14:30") #For test
    finish = now.at_beginning_of_day
    start = finish - 1.day
    @human_date = "#{I18n.l(start.to_date, :format => :long )}"
    @date = "#{start.to_date}"
    @date_range = {:start => start, :finish => finish}
    @subject = "监控日报[#{@human_date}]"
    @user = user
    @tenant = user.tenant
    @operator = @tenant.operator
    find_views
    setup_email(user, @views)
  end

  def weekly(user)
    now = Time.now
    #now = Time.parse("2010-7-13 14:30") #For test
    finish = now.at_beginning_of_week
    start = finish - 7.days
    @human_date = "#{I18n.l(start.to_date, :format => :long )} - #{I18n.l(finish.to_date - 1.day, :format => :long )}"
    @date = "#{start.to_date},#{(finish.to_date - 1.day)}"
    @date_range = {:start => start, :finish => finish}
    @subject = "监控周报[#{@human_date}]"
    @user = user
    @tenant = user.tenant
    @operator = @tenant.operator
    find_views
    setup_email(user, @views)
  end

  def monthly(user)
    now = Time.now
    #now = Time.parse("2010-7-13 14:30") #For test
    finish = now.at_beginning_of_month
    start = finish - 1.month
    @human_date = "#{I18n.l(start.to_date, :format => :month_and_year)}"
    @date = "#{start.to_date},#{(finish.to_date - 1.day)}"
    @date_range = {:start => start, :finish => finish}
    @subject = "监控月报[#{@human_date}]"
    @user = user
    @tenant = user.tenant
    @operator = @tenant.operator
    find_views
    setup_email(user, @views)
  end

  protected
  def setup_email(user, views)
    operator = @operator
    ActionMailer::Base.default_url_options[:host] = operator.host
    @recipients  = "#{user.email}"
    @from        = "#{operator.title} <report@chinaccnet.com>"
    @sent_on     = Time.now
    #@content_type = "text/html"
    #@reply_to    = "help@chinaccnet.com"
    @body[:user] = user
    @body[:operator] = operator
    @body[:views] = views
    #@template 
  end

  def find_views
    @views = []
    [Site, Host, App, Device].each do |model|
      model_name = model.name.downcase
      cont = model_name.pluralize
      objects = @user.send(cont.to_sym)
      if objects.size > 0
        status_data = Status.history(objects, @date_range)
        options = @date_range.merge(:show_url => "http://#{@operator.host}/#{cont}/${id}", :more_url => "http://#{@operator.host}/#{cont}/${id}/avail#{@date.blank? ? nil : "?date=" + @date }")
        data_view = Status.view(model, status_data, options)
        data_view.name = @human_date + data_view.name + " [<a href=\"http://#{@operator.host}/avail/#{cont}#{@date.blank? ? nil : "?date=" + @date }\">查看</a>]"
        data_view.template = "datagrid_text"
        @views << data_view
      end
    end
  end

end
