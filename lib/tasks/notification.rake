namespace :notification do
  desc "Send alerts notification by email."
  task :mail_alerts => :environment do
    file = File.join(RAILS_ROOT, "log", "notification.log")
    logger = Logger.new(file)
    now = Time.now
    @alert_notifications = AlertNotification.all({
      :include => ['service', 'tenant'] + AlertNotification.source_names,
      :conditions => {:method => 0, :status => 0}
    })
    if @alert_notifications.size > 0
      notifications = []
      @alert_notifications.each do |noti|
        tmail = AlertMailer.notify(noti).deliver
        notifications << {
          :method => 0,
          :status => 1,
          :address => noti.tenant.email,
          :contact => noti.tenant.name,
          :tenant_id => noti.tenant_id,
          :type_id => 1,
          :title => tmail.subject,
          :summary => tmail.parts.first.body,
          :content => tmail.parts.second.body
        }
      end
      Notification.create(notifications) if notifications.size > 0
      AlertNotification.update_all({:status => 1}, {:id => @alert_notifications.collect{|x| x.id}})
    end
    logger.info("#{now}(#{(Time.now - now)*100}ms)\nSend alert notifications #{@alert_notifications.size}\n\n")
  end

  desc "Send alerts notification by SMS."
  task :sms_alerts => :environment do
    require 'sms_socket'
    file = File.join(RAILS_ROOT, "log", "notification.log")
    logger = Logger.new(file)
    now = Time.now
    @alert_notifications = AlertNotification.all({
      :include => ['service', 'tenant'] + AlertNotification.source_names,
      :conditions => {:method => 1, :status => 0}
    })
    if @alert_notifications.size > 0
      notifications = []
      @alert_notifications.each do |noti|
        user = noti.user
        ob = noti.service || noti.source
        status = noti.human_status_name
        name = noti.source.name + (noti.service ? " / " + noti.service.name : "")
        subject = "[#{I18n.translate(noti.object_name)}]#{name} #{status}"
        body = name + "于" + noti.changed_at.strftime("%m-%d %H:%M") + status + "。"
        url = "http://" + noti.tenant.operator.host + "/" + ob.class.name.downcase.pluralize + "/" + ob.id.to_s
        url1 = noti.tenant.operator.host + "/" + ob.class.name.downcase.pluralize + "/" + ob.id.to_s
        url2 = "/" + ob.class.name.downcase.pluralize + "/" + ob.id.to_s
        if body.mb_chars.size > 70
          body = body.mb_chars[0..69]
        elsif (body + url).mb_chars.size < 70
          body = body + url
        elsif (body + url1).mb_chars.size < 70
          body = body + url1
        elsif (body + url2).mb_chars.size < 70
          body = body + url2
        end
        #user.mobile = "18757111138"
        status = 1
        if user.mobile.blank?
          status = 3 #
          status_msg = "无短信号码"
        else
          client = SMSSocket.open("sms.todaynic.com", "20002")
          client.user = "ms25239"
          client.password = "mtuwnj"
          client.send(user.mobile, body)
          unless client.is_success?
            status = 3
            status_msg = client.respond
          end
          client.close
        end

        notifications << {
          :method => 1,
          :status => status,
          :status_msg => status_msg,
          :user_id => user.id,
          :address => user.mobile,
          :contact => user.login,
          :tenant_id => noti.tenant_id,
          :type_id => 1,
          :title => subject,
          :summary => body,
          :content => body
        }
      end
      Notification.create(notifications) if notifications.size > 0
      AlertNotification.update_all({:status => 1}, {:id => @alert_notifications.collect{|x| x.id}})
    end
    logger.info("#{now}(#{(Time.now - now)*100}ms)\nSend alert notifications by sms #{@alert_notifications.size}\n\n")
  end

  desc "Send report notification by email."
  task :mail_report, [:frequency] => :environment do |t, args|
    frequency = args[:frequency]
    frequency = "weekly" unless ["weekly", "daily", "monthly"].include?(frequency)
    file = File.join(RAILS_ROOT, "log", "notification.log")
    logger = Logger.new(file)
    now = Time.now

    @users = Tenant.all(:conditions => {frequency.to_sym => true}, :include => [:apps, :sites, :hosts, :devices, :tenant]).select{|u| u.apps.size > 0 or u.sites.size > 0 or u.hosts.size > 0 or u.devices.size > 0 }
    notifications = []
    @users.each do |user|
      tmail = case frequency
              when "weekly"
                ReportNotifier.deliver_weekly(user)
              when "daily"
                ReportNotifier.deliver_daily(user)
              when "monthly"
                ReportNotifier.deliver_monthly(user)
              end
      notifications << {
        :method => 0,
        :status => 1,
        :user_id => user.id,
        :address => user.email,
        :contact => user.login,
        :tenant_id => user.tenant_id,
        :type_id => 2,
        :title => tmail.subject,
        :summary => tmail.subject,
        :content => tmail.parts.first.body
      }
    end
    Notification.create(notifications) if notifications.size > 0
    logger.info("#{now}(#{(Time.now - now)*100}ms)\nSend report[#{frequency}] notifications #{@users.size}\n\n")
  end
end
