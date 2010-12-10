class NotifyRule < ActiveRecord::Base
  @@methods = Notification.methods
  @@source_types = [{:id => 0, :name => "service", :title => "服务"}, {:id => 1, :name => "host", :title => "主机"}, {:id => 2, :name => "app", :title => "应用"}, {:id => 3, :name => "site", :title => "网站"}]
  @@alert_severities = [{:id => 0, :name => "ok", :title => "恢复正常"}, {:id => 1, :name => "warning", :title => "告警"}, {:id => 2, :name => "critical", :title => "故障"}, {:id => 3, :name => "unknown", :title => "未知错误"}]
  cattr_reader :methods, :source_types, :alert_severities
  belongs_to :user
  #validates_uniqueness_of :name, :scope => :user_id

  class << self
    def default_rules methods = "email", types = "host, app, service", severities = "ok, critical", ext_param = {}
      ar = []
      types = @@source_types.select{|x| types.include?(x[:name])}
      severities = @@alert_severities.select{|x| severities.include?(x[:name])}
      @@methods.select{|x| methods.include?(x[:name])}.each do |m|
        types.each do |t|
          severities.each do |l|
            ar << {:method => m[:id], :source_type => t[:id], :alert_severity => l[:id], :name => "#{m[:name]}_#{t[:name]}_#{l[:name]}" }.update(ext_param)
          end
        end
      end
      ar
    end
  end
end
