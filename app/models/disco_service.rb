class DiscoService < ActiveRecord::Base
  @@object_types = Service.object_types
  @@object_names = Service.object_names
  cattr_reader :object_types, :object_names

  @@object_types.each do |s|
    belongs_to s[:name].to_sym, :foreign_key => 'object_id'
  end
  belongs_to :type, :foreign_key => 'type_id', :class_name => 'ServiceType'
  belongs_to :tenant

  def service
    t = self.type
    check_interval = t.check_interval
    package = self.tenant.package
    check_interval = check_interval > package.min_check_interval ? check_interval : package.min_check_interval if package
    Service.new({
      :name => self.name,
      :object_type => self.object_type,
      :object_id => self.object_id,
      :tenant_id => self.tenant_id,
      :agent_id => self.agent_id,
      :type_id => self.type_id,
      :params => self.params,
      :summary => self.summary,
      :ctrl_state => t.ctrl_state,
      :check_interval => check_interval,
      :threshold_critical => t.threshold_critical,
      :threshold_warning => t.threshold_warning
    })
  end

  def object_name
    @object_name || (@object_name = @@object_types.select{ |x| x[:id] == object_type}.first[:name])
  end

  def object
    send(object_name)
  end
end
