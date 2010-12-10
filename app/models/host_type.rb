class HostType < ActiveRecord::Base
  has_many :service_types, :conditions => { :object_type => 1 }, :foreign_key => 'object_id'
  has_many :hosts, :foreign_key => 'type_id'

  validates_presence_of :name
  validates_presence_of :parent_id
  def service_types
    ServiceType.find_by_sql("select * from service_types t1 where t1.object_type=1 and t1.object_id in (select t2.id from host_types t2 where instr('#{name}',t2.name) > 0)" )
  end

  def service_types_with_view(visible_type)
    ServiceType.find_by_sql(["select t1.* from service_types t1, views t2 where t1.object_type=1 and t1.object_id in (select t2.id from host_types t2 where instr('#{name}',t2.name) > 0) and t1.id = t2.visible_id and t2.visible_type = ?", visible_type])
  end

  def ctrl_service_types
    ServiceType.find_by_sql("select * from service_types t1 where t1.object_type=1 and t1.ctrl_state=1 and t1.object_id in (select t2.id from host_types t2 where instr('#{name}',t2.name) > 0)" )
  end

  def hosts
    #Host.all :conditions => { :type_id => self.class.all(:conditions => ["name like concat(?,'%')", name]) }
    Host.all :conditions => ["type_id in (select id from " + self.class.table_name + " where name like concat(?,'%'))" , name]
  end
end
