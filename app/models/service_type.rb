class ServiceType < ActiveRecord::Base
  @@object_types = [nil, 'host', 'app', 'site', 'device']
  cattr_reader :object_types

  belongs_to :host_type, :foreign_key => 'object_id'
  belongs_to :app_type, :foreign_key => 'object_id'
  has_many :params, :foreign_key => 'type_id', :class_name => "ServiceParam"
  has_many :thresholds, :order => "level", :foreign_key => 'type_id', :class_name => "ServiceThreshold"
  has_many :metrics, :class_name => "MetricType", :foreign_key => 'type_id'
  has_many :services, :foreign_key => 'type_id'

  validates_presence_of :name
  validates_presence_of :alias
  validates_presence_of :object_id
  validates_presence_of :check_interval
  validates_presence_of :object_type
  validates_presence_of :command
  validates_inclusion_of :discover_type, :in => [1,2,3]

  def type_and_alias
    I18n.t(object_type_name) + " - " + read_attribute(:alias)
  end

  def object_type_name
    @@object_types[object_type]
  end

  #def services(object_type, object_id)
  #  Service.all(:conditions => ["type_id = ? and object_type = ? and object_id = ?", id, object_type, object_id])
  #end

  def discover_type
    [nil, "snmp", "ssh", "local"]
  end
end
