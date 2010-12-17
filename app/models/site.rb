class Site < ActiveRecord::Base
  has_many :services, :conditions => { :object_type => 3 }, :foreign_key => 'object_id', :dependent => :destroy
  has_many :disco_services, :conditions => { :object_type => 3 }, :foreign_key => 'object_id', :dependent => :destroy
  has_many :alerts, :conditions => { :source_type => 3 }, :foreign_key => "source_id", :dependent => :destroy
  has_many :alert_notifications, :conditions => { :source_type => 3 }, :foreign_key => "source_id", :dependent => :destroy
  belongs_to :group
  belongs_to :tenant

  validates_presence_of :name
  #validates_format_of       :name,     :with => /\A[^[:cntrl:]<>\/&]*\z/,  :message => "不能含有<>&", :allow_nil => true
  validates_length_of       :name,     :maximum => 50
  validates_uniqueness_of :name, :scope => [:tenant_id]
  #validates_format_of :url, :with => /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
  #Url like this:
  # http://www.google.com
  # http://222.177.4.4
  #
  validates_format_of :url, :with => /^(https?):\/\/[-\w]+(\.\w[-\w]*)+$/

    after_create :gen_ctrl
  after_create :generate_services
  before_save :parse_url

  def dn
    "site=#{id}"
  end

  #def before_create
  #  uuid = App.find_by_sql("select uuid() uid from dual")[0].uid
  #  send("uuid=",uuid)
  #end

  def parse_url
    uri = URI.parse(url)
    self.addr = uri.host
    self.port = uri.port
    self.path = uri.path + (uri.query ? "?#{uri.query}" : "")
  end

  def status_data
    @status_data ||=StatusView.new(self)
  end

  def status1
    @status1 ||=Status1.new(self)
  end

  def ctrl_service
    @ctrl_service || (@ctrl_service = Service.first(:conditions => {:object_type => 3, :object_id => self.id, :ctrl_state => 1}))
  end

  def status_name
    status && self.class.status[status] ? self.class.status[status] : 'pending'
  end

  def human_status_name
    I18n.t("status.site.#{status_name}")
  end

  private
  def generate_services
    #ping service
    generate_service 23
    #dns service
    generate_service 25
  end

  def generate_service type
    service = Service.gen(:object_type => 3, :type_id => type, :tenant_id => self.tenant_id, :object_id => self.id, :agent_id => self.agent_id)
    service.save
  end

  def gen_ctrl
    #http service
    ctrl = Service.gen(:object_type => 3, :type_id => 24, :tenant_id => self.tenant_id, :object_id => self.id, :ctrl_state => 1, :agent_id => self.agent_id)  
    ctrl.save
  end

  class << self
    def status
      ['up', 'down', 'pending']
    end

    def status_colors
      ["33FF00", "F83838", "ACACAC"]
    end
  end

end
