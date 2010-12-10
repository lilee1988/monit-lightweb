class Status1
  @@family = [:Status, :StatusRollup1, :StatusRollup12, :StatusRollup24]
  def initialize(object)
    @object = object
    @uuid = @object.uuid
    @db = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
  end


  def history options
    finish = options[:finish].to_i
    start = options[:start].to_i
    distance=finish-start
    if distance<=1.days
      family=@@family[1]
    end
    if distance>1.days && distance<=7.days
      family=@@family[2]
    end
    if distance>7.days
      family=@@family[3]
    end
    db = @db.get(family, @uuid, :start => start.to_s, :finish => finish.to_s)
    db
  end

  def history_view
    View.first(:conditions => {:visible_type => "host_availabilities", :enable => 1}, :include => ['items'])
  end

  def service_history_view
    View.first(:conditions => {:visible_type => "service_availability", :enable => 1}, :include => ['items'])
  end

  def site_history_view
    View.first(:conditions => {:visible_type => "site_availability", :enable => 1}, :include => ['items'])
  end

  def device_history_view
    View.first(:conditions => {:visible_type => "device_availability", :enable => 1}, :include => ['items'])
  end

  def app_history_view
    View.first(:conditions => {:visible_type => "app_availability", :enable => 1}, :include => ['items'])
  end

end
