class App < ActiveRecord::Base
  has_many :services, :conditions => { :object_type => 2 }, :foreign_key => 'object_id', :dependent => :destroy
  has_many :disco_services, :conditions => { :object_type => 2 }, :foreign_key => 'object_id', :dependent => :destroy
  belongs_to :type, :foreign_key => 'type_id', :class_name => 'AppType'
  belongs_to :host
  has_many :alerts, :conditions => "source_type = 2", :foreign_key => "source_id", :dependent => :destroy
  has_many :alert_notifications, :conditions => "source_type = 2", :foreign_key => "source_id", :dependent => :destroy
  belongs_to :group
  belongs_to :tenant

  validates_presence_of :name
  validates_presence_of :host_id
  validates_presence_of :type_id
  #validates_format_of       :name,     :with => Authentication.name_regex,  :message => "不能含有\\/<>&", :allow_nil => true
  validates_length_of       :name,     :maximum => 100
  validates_uniqueness_of :name, :scope => [:tenant_id]
  after_create :gen_ctrl

  def status_data
    @status_data ||=StatusView.new(self)
  end

  def status1
    @status1 ||=Status1.new(self)
  end

  def dn
    "app=#{id}"
  end

  def status_name
    status && self.class.status[status] ? self.class.status[status] : 'pending'
  end

  def human_status_name
    I18n.t("status.app.#{status_name}")
  end

  def ctrl_service
    @ctrl_service || (@ctrl_service = Service.first(:conditions => {:object_type => 2, :object_id => self.id, :ctrl_state => 1}))
  end

  def gen_ctrl
    ctrl_type = self.type.ctrl_service_types.first
    if ctrl_type
      ctrl = Service.gen(:type_id => ctrl_type.id, :tenant_id => self.tenant_id, :object_id => self.id, :ctrl_state => 1, :agent_id => self.agent_id)  
      ctrl.save
    end
  end

  class << self
    @@status = ['up', 'down', 'pending']
    def status
      @@status
    end

    def status_colors
      ["33FF00", "F83838", "ACACAC"]
    end

    # 返回当前系统中应用的健康性
    def heath tenant_id
      heath_row = find :first, :select => "count(case status when 0 then 1 else null end) as healthy, count(*) as host_count", :conditions => {:tenant_id => tenant_id}
      return 0 if heath_row.host_count.to_i == 0
      ((heath_row.healthy.to_f / heath_row.host_count.to_f) * 100).reserve2
    end
  end
end
