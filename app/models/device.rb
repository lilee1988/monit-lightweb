class Device < ActiveRecord::Base
  has_many :services, :conditions => { :object_type => 4 }, :foreign_key => 'object_id', :dependent => :destroy
  has_many :disco_services, :conditions => { :object_type => 4 }, :foreign_key => 'object_id', :dependent => :destroy
  belongs_to :agent 
  belongs_to :type, :foreign_key => 'type_id', :class_name => 'DeviceType'
  has_many :alerts, :conditions => "source_type = 4", :foreign_key => "source_id", :dependent => :destroy
  has_many :alert_notifications, :conditions => "source_type = 4", :foreign_key => "source_id", :dependent => :destroy
  belongs_to :group
  belongs_to :tenant

  validates_presence_of :name
  validates_presence_of :addr
  validates_presence_of :type_id
  validates_presence_of :port, :if => :is_support_snmp?
  validates_presence_of :snmp_ver, :if => :is_support_snmp?
  validates_inclusion_of :snmp_ver, :in => ["v1", "v2c"], :if => :is_support_snmp?
  validates_presence_of :community, :if => :is_support_snmp?
  validates_format_of       :name,     :with => Authentication.name_regex,  :message => "不能含有\\/<>&", :allow_nil => true
  validates_length_of       :name,     :maximum => 100
  validates_uniqueness_of :name, :scope => [:tenant_id]
  after_create :gen_ctrl

  def dn
    "device=#{id}"
  end

  def discovered?
    discovery_state == 1
  end

  #是否支持snmp
  def is_support_snmp?
    self.is_support_snmp == 1
  end

  #是否支持本机agent
  def is_support_agent?
    !agent.nil?
  end

  def metric 
    db = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
    data = db.get(:Host, uuid)
  end

  def status_name
    status && self.class.status[status] ? self.class.status[status] : 'pending'
  end

  def human_status_name
    I18n.t("status.device.#{status_name}")
  end

  def status_data
    @status_data ||=StatusView.new(self)
  end

  def status1
    @status1 ||=Status1.new(self)
  end

  def ctrl_service
    @ctrl_service || (@ctrl_service = Service.first(:conditions => {:object_type => 4, :object_id => self.id, :ctrl_state => 1}))
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
  end
end
