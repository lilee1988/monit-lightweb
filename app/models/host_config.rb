class HostConfig

  @@family = [:Entry]
  
  def self.configinfo (object)
    @uuid = object.uuid
    @db = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
    db = @db.get(@@family, @uuid)
    db
  end

  def self.serviceparams(uuid,param)
    @db = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
    db = @db.get(@@family, uuid,param)
    db
  end

end
