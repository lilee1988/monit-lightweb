module MonitorObject
  def self.included(base)
    base.has_many :services # 该监控对象下的所有监控服务
    base.extend self
    class << base
      # 定义需要优先显示的服务数据
      define_method(:prior_service_count) { 5 } unless respond_to?(:prior_service_count)
    end
  end

  # 返回主机或应用的所有告警
  def alerts
    #TODO
  end
  
  # 返回不正常的服务
  def unnormal_services
  end

  # 返回主机/应用下需要优先显示的服务，当用户在浏览主机表格视图或缩略视图时，需要同时显示
  # 某个主机/应用下的服务状态，该方法根据一定的规则，返回主机/应用下的部分服务，通常，根据服务的
  # 状态或告警的级别进行筛选。<br>
  # 在主机和应用中需要特殊规则请覆盖此方法。
  def prior_services
  end
  
end
