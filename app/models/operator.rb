class Operator < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  has_many :tenants,:after_add=>:aaa
  has_many :packages
def aaa
end

  validates_presence_of     :host
  validates_length_of       :host,    :within => 3..40
  validates_uniqueness_of   :host
 # validates_format_of       :login,    :with => /\A\w[\w\.\-_]+\z/, :message => "允许字母，数字以及字符.-_"
  attr_accessor  :password
  attr_accessor :old_password

  after_create :init_packages


  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    #u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login] # need to get the salt
    u = find :first, :conditions => { :host => login } # need to get the salt
    #u && u.authenticated?(password) ? (u.active? ? u : false) : nil
    u && u.authenticated?(password) ? u : nil
  end

  def login
    host
  end
  def login=(value)
    write_attribute :host, (value ? value.downcase : nil)
  end
 
  def add_tenant(attrs)
    attrs.symbolize_keys!
    user=User.new(attrs)
    tenant=tenants.new({:name => user.login, :email => user.email})

    tenant.users << user
    tenant.save
    user
  end
  
  private
  def init_packages
    Package.defaults.each do |p|
      self.packages.create(p)
    end
  end

  def make_activation_code
    #self.activation_code = self.class.make_token
    self.activated_at = Time.now.utc
    self.activation_code = nil
  end
end
