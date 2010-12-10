class AppType < ActiveRecord::Base
  has_many :service_types, :conditions => { :object_type => 2 }, :foreign_key => 'object_id'
  has_many :apps, :foreign_key => 'type_id'

  def view
    name.split('/').last
  end
  def service_types
    ServiceType.find_by_sql("select * from service_types t1 where t1.object_type=2 and t1.object_id in (select t2.id from app_types t2 where instr('#{name}',t2.name) > 0)" )
  end

  def ctrl_service_types
    ServiceType.find_by_sql("select * from service_types t1 where t1.object_type=2 and t1.ctrl_state=1 and t1.object_id in (select t2.id from app_types t2 where instr('#{name}',t2.name) > 0)" )
  end

  def apps
    #Host.all :conditions => { :type_id => self.class.all(:conditions => ["name like concat(?,'%')", name]) }
    App.all :conditions => ["type_id in (select id from " + self.class.table_name + " where name like concat(?,'%'))" , name]
  end
end
