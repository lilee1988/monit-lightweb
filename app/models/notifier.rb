class Notifier < ActionMailer::Base
  layout "email"

  def alert(notification)
    setup_email(notification)
  end

  protected
  def setup_email(notification)
    user = notification.user
    operator = notification.tenant.operator
    ActionMailer::Base.default_url_options[:host] = operator.host
    status = notification.human_status_name
    name = notification.source.name + (notification.service ? " / " + notification.service.name : "")
    #name = (notification.service || notification.source).name
    @recipients  = "#{user.email}"
    @from        = "#{operator.title} <alert@chinaccnet.com>"
    @subject     = "[#{I18n.translate(notification.object_name)}]#{name} #{status}"
    @sent_on     = Time.now
    #@content_type = "text/html"
    #@reply_to    = "help@chinaccnet.com"
    @body[:user] = user
    @body[:operator] = operator
    @body[:notification] = notification
    #@template 
  end
end
