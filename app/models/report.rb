class Report
  class << self
    #Return TOPN of service metric
    #Report.top(:n => 5, :tenant => "root", :service_type => "disk", :sort => "-usage")
    #return value:
    #[<OrderedHash {:host => #<Host>, :service => #<Service>, "usage"=>"50", "total"=>"20", "used"=>"20", "avail"=>"10"}>]

    def top(options = {})
      options = {:tenant => "root", :service_type => "disk", :n => 5, :sort => "-usage"}.update(options)
      tenant = options[:tenant]
      service_type = options[:service_type]
      n = options[:n]
      sort = options[:sort]
      db = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
      data = db.get(:Top, "#{tenant}.#{service_type}")
      data = data.to_a
      unless sort.blank?
        if sort[0]!=45
          reverse = false
        else
          reverse = true
          sort = sort.gsub(/^\-/,"")
        end
        data.sort! do |b, a|
          (reverse ? -1 : 1)*(a[1][sort].to_i <=> b[1][sort].to_i)
        end
      end
      data = data[0, n]
      output = []
      if data.size > 0
        services = self.find_resource data.collect { |x| x[0] }
        services = services.inject({}) { |h,m| h[m.uuid] = m; h }
        data.each do |x|
          uuid = x[0]
          d = x[1]
          if s = services[uuid]
            d[:service_id] = s.id
            d[:service_name] = s.name
            d[:object_type] = s.object_name
            [:host_id, :host_name, :app_id, :app_name].each do |x|
              d[x] = s[x]
            end
            output << d
          end
        end
      end
      output
    end
    def find_resource uuids
      Service.all({ 
        :select => "services.id, services.uuid, services.name, services.object_type, t1.id host_id, t1.name host_name, t2.id app_id, t2.name app_name",
        :joins=>"LEFT JOIN hosts t1 ON t1.id = services.object_id AND services.object_type = 1 LEFT JOIN apps t2 ON t2.id = services.object_id AND services.object_type = 2",
        :conditions => { :uuid => uuids }
      })
    end
  end
end
