class Host < ActiveRecord::Base
  has_many :apps, :dependent => :destroy # 返回该主机下的所有应用
  has_many :services, :conditions => { :object_type => 1 }, :foreign_key => 'object_id', :dependent => :destroy
  has_many :disco_services, :conditions => { :object_type => 1 }, :foreign_key => 'object_id', :dependent => :destroy
  belongs_to :agent 
  #has_one :control_service, :conditions => { :object_type => 1, :ctrl_state => 1 }, :foreign_key => 'object_id', :class_name => "Service"
  belongs_to :type, :foreign_key => 'type_id', :class_name => 'HostType'
  belongs_to :state, :foreign_key => "status", :class_name => "HostState"
  has_many :alerts, :conditions => "source_type = 1", :foreign_key => "source_id", :dependent => :destroy
  has_many :alert_notifications, :conditions => "source_type = 1", :foreign_key => "source_id", :dependent => :destroy
  belongs_to :group
  belongs_to :tenant

  validates_presence_of :name
  validates_presence_of :addr
  validates_presence_of :type_id
  validates_presence_of :port, :if => :is_support_snmp?
  validates_presence_of :snmp_ver, :if => :is_support_snmp?
  validates_inclusion_of :snmp_ver, :in => ["v1", "v2c"], :if => :is_support_snmp?
  validates_presence_of :community, :if => :is_support_snmp?
  #validates_format_of       :name,     :with => Authentication.name_regex,  :message => "不能含有\\/<>&", :allow_nil => true
  validates_length_of       :name,     :maximum => 100
  validates_uniqueness_of :name, :scope => [:tenant_id]
  after_create :gen_ctrl

  def discovered?
    discovery_state == 1
  end

  #是否支持snmp
  def is_support_snmp?
    self.is_support_snmp == 1
  end

  #是否支持ssh
  def is_support_ssh?
    self.is_support_ssh == 1
  end

  def dn
    "host=#{id}"
  end

  #has_agent
  def has_agent
    unless @has_agent_cache
      @has_agent_cache = true
      @has_agent = Agent.first(:conditions => {:host_id => self.id})
    end
    @has_agent
  end

  #是否支持本机agent
  def is_support_agent?
    !self.has_agent.nil?
  end

  def metric 
    db = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
    data = db.get(:Host, uuid)
  end

  def status_data
    @status_data ||=StatusView.new(self)
  end

  def status1
    @status1 ||=Status1.new(self)
  end

  # 返回主机磁盘所有分区和用户指定目录的监控状态

  def disk_unilization
  end

  # 返回系统的平均负载监控状态
  def system_load
  end

  # 返回CPU使用率的监控状态
  def cpus_unilization
  end

  # 返回不正常的应用，当应用下存在告警，则意味着该应用不正常。
  def unnormal_apps
  end

  def status_name
    status && self.class.status[status] ? self.class.status[status] : 'pending'
  end

  def human_status_name
    I18n.t("status.host.#{status_name}")
  end

  def ctrl_service
    @ctrl_service || (@ctrl_service = Service.first(:conditions => {:object_type => 1, :object_id => self.id, :ctrl_state => 1}))
  end

  def gen_ctrl
    ctrl_type = self.type.ctrl_service_types.first
    if ctrl_type
      ctrl = Service.gen(:type_id => ctrl_type.id, :tenant_id => self.tenant_id, :object_id => self.id, :ctrl_state => 1, :agent_id => self.agent_id)  
      ctrl.save
    end
  end

  class << self

    def discovery_state
      ['undiscovered', 'discovered', 'rediscovery', 'undiscoverable']
    end

    def status
      ['up', 'down', 'pending', 'unreachable']
    end

    def status_colors
      ["33FF00", "F83838", "ACACAC", "F83838"]
    end

    # 返回当前系统中主机的健康性
    def heath tenant_id
      heath_row = find :first, :select => "count(case status when 0 then 1 else null end) as healthy, count(*) as host_count", :conditions => {:tenant_id => tenant_id}
      return 0 if heath_row.host_count.to_i == 0
      return ((heath_row.healthy.to_f / heath_row.host_count.to_f) * 100).reserve2
    end
  end
end
