class AlertMailer < ActionMailer::Base
  layout "email"
  default :from => "#{I18n.t("production_title")} <alert@chinaccnet.com>"
  def notify(notification)
    @notification = notification
    @tenant = @notification.tenant
    status = @notification.human_status_name
    name = @notification.source.name + (@notification.service ? " / " + @notification.service.name : "")
    @subject     = "[#{I18n.translate(@notification.object_name)}]#{name} #{status}"
    #@sent_on     = Time.now
    #@content_type = "text/html"
    #@reply_to    = "help@chinaccnet.com"
    mail(:to => @tenant.email, :subject => @subject) do |format|
      format.text
      format.html
    end
  end
end
