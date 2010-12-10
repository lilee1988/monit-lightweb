# To change this template, choose Tools | Templates
# and open the template in the editor.

class Alert < ActiveRecord::Base
  @@source_types = Service.object_types
  @@source_names = Service.object_names
  cattr_reader :source_types, :source_names

  @@source_types.each do |s|
    belongs_to s[:name].to_sym, :foreign_key => "source_id"
  end
  belongs_to :service, :foreign_key => "service_id"

  def source_name
    @source_name || (@source_name = @@source_types.select{ |x| x[:id] == source_type}.first[:name])
  end

  #告警发生源[网站，应用，主机，网络]
  def source
    send(source_name)
  end

  def object
    service || source
  end

  def object_name
    service ? "service" : source_name
  end

  def status_type_name
    [nil, "transient", "permanent"][status_type]
  end

  def human_status_type_name
    I18n.t("status_type.#{status_type_name}")
  end

  def status_name
    object.class.status[status]
  end

  def human_status_name
    I18n.t("status.#{object_name}.#{status_name}")
  end

  def alias
    ob = service || source
    ob.name + ob.human_status_name
  end

  def severity_name
    severity && self.class.severity[severity] ? self.class.severity[severity] : 'unknown'
  end

  def human_severity_name
    I18n.t("status.alert." + severity_name)
  end

  class << self
    def severity
      ['clear', 'warning', 'critical', 'information']
    end
  end
end
