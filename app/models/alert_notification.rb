class AlertNotification < Alert
  @@intervals_select = [["30分钟", 1800], ["1小时", 3600], ["2小时", 7200], ["1天", 3600*24]]
  @@delay_select = [["立即", 0], ["延迟5分钟", 5*60], ["延迟10分钟", 10*60], ["延迟30分钟", 30*60], ["延迟1小时", 60*60]]
  @@intervals = @@intervals_select.collect{|x| x[1]}
  @@delay = @@delay_select.collect{|x| x[1]}
  cattr_reader :intervals, :intervals_select, :delay, :delay_select

  set_table_name 'alert_notifications'
  belongs_to :user
  belongs_to :tenant

  def last_status_name
    self.class.status[object_name.to_sym][alert_last_status]
  end

  def human_last_status_name
    I18n.t("status.notification.#{object_name}.#{last_status_name}")
  end

  def status_name
    self.class.status[object_name.to_sym][alert_status]
  end

  def human_status_name
    I18n.t("status.notification.#{object_name}.#{status_name}")
  end

  class << self
    @@status = {
      :host => ['recovery', 'down', nil, 'unreachable'],
      :device => ['recovery', 'down', nil, 'unreachable'],
      :app => ['recovery', 'down'],
      :site => ['recovery', 'down'],
      :service => ['recovery', 'warning', 'critical', 'unknown']
    }
    def status
      @@status
    end
  end
end
