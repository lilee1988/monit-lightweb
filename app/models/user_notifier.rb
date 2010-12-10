class UserNotifier < ActionMailer::Base
  layout "email"
  helper :application
  def signup_notification(user)
    setup_email(user)
    @subject    += '注册通知'
  end

  def resend_password(user)
    setup_email(user)
    @subject    += "重设#{user.login}的密码"
  end

  def activation(user)
    setup_email(user)
    @subject    += '账号成功激活!'
  end

  def gen_bill(tenant,bill)
    operator=tenant.operator
    recipients		tenant.email
    from					"#{operator.title} <no-reply@chinaccnet.com>"
    subject       "来自[#{operator.title}]的账单!"
    sent_on     	Time.now
    body					:tenant => tenant,:operator=>operator,:bill=>bill
    content_type  'text/html'
  end

  def gen_operator_bill(operator,bill)
    recipients		operator.email
    from					"#{operator.title} <no-reply@chinaccnet.com>"
    subject       "[来自Monit的账单!]"
    sent_on     	Time.now
    body					:operator=>operator,:bill=>bill
    content_type  'text/html'
  end

  def gen_order(tenant,order)
    operator=tenant.operator
    recipients		tenant.email
    from					"#{operator.title} <no-reply@chinaccnet.com>"
    subject       "来自[#{operator.title}]的信息!"
    sent_on     	Time.now
    body					:tenant => tenant,:operator=>operator,:order=>order
    content_type  'text/html'
  end

  def destroy_order(tenant,order)
    operator=tenant.operator
    recipients		tenant.email
    from					"#{operator.title} <no-reply@chinaccnet.com>"
    subject       "来自[#{operator.title}]的信息!"
    sent_on     	Time.now
    body					:tenant => tenant,:operator=>operator,:order=>order
    content_type  'text/html'
  end


  protected
  def setup_email(user)
    operator = user.tenant.operator
    ActionMailer::Base.default_url_options[:host] = operator.host
    @recipients  = "#{user.email}"
    @from        = "#{operator.title} <no-reply@chinaccnet.com>"
    @subject     = "[#{operator.title}] "
    @sent_on     = Time.now
    #@reply_to    = "help@chinaccnet.com"
    @content_type = "text/html"
    @body[:user] = user
    @body[:operator] = operator
  end
end
