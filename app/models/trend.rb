class Trend

   def self.area_select(object,current_user)
    case object.to_i
    when 1
      Host.all :conditions=>{:tenant_id => current_user.tenant_id}
    when 2
      App.all :conditions=>{:tenant_id => current_user.tenant_id}
    when 3
      Site.all :conditions=>{:tenant_id => current_user.tenant_id}
    when 4
      Device.all :conditions=>{:tenant_id => current_user.tenant_id}
    else
      nil
    end     
  end

end
