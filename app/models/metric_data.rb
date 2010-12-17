class MetricData
  FAMILY = [:Metric, :MetricRollup1, :MetricRollup12, :MetricRollup24]
  #DB = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
  MODELS = [Metric, MetricHourly, MetricDaily]

  def initialize(service)
    @service = service
    @uuid = @service.uuid
    @dn = @service.dn
    @interval = @service.check_interval
    @allow_distance = @interval * 1.2
    @history_cache = {}
  end

  #def default_view
  #  View.first(:conditions => {:visible_type => "service_default", :visible_id => @service.type_id, :enable => 1}, :include => ['items'])
  #end

  #def views
  #  View.all(:conditions => {:visible_type => "service_current", :visible_id => @service.type_id, :enable => 1}, :include => ['items'])
  #end

  #def history_views
  #  View.all(:conditions => {:visible_type => "service_history", :visible_id => @service.type_id, :enable => 1}, :include => ['items'])
  #end

  def history options
    start = options[:start].to_i
    finish = options[:finish].to_i
    key = "C#{start}_#{finish}"
    return @history_cache[key] if @history_cache.has_key?(key)

    config = self.class.config(options[:start], options[:finish], @interval)
    #data = DB.get(config[:family], @uuid, :start => start.to_s, :finish => finish.to_s, :count => 1000)
    data = config[:model].where({:dn => @dn, :ts => { "$gt" => start, "$lt" => finish }}).asc(:ts).to_a
    data.collect!{|doc| doc.attributes}

    set_history data, start, finish, config[:interval]
  end

  def set_history data, start, finish, interval
    start = start.to_i
    finish = finish.to_i
    key = "C#{start}_#{finish}"
    @history_interval = interval
    @history_allow_distance = @history_interval * 1.2
    @history_cache[key] = complete(data, start, finish)
  end

  def current=(data)
    set_current(data)
  end

  def current
    return @current if @has_current
    #set_current(DB.get(:Metric, @uuid, :count => 1, :reversed => true))
    data = Metric.last(:conditions => {:dn => @dn})
    data = data ? data.attributes : nil
    set_current(data)
  end

  #  def last
  #    data = DB.get(:Metric, @uuid, :count => 1, :reversed => true)
  #    data = data.to_a.first
  #    data && data[1]
  #  end

  private

  #允许值与当前时间的间隔大于检测频度20%
  def set_current data
    @has_current = true
    #data = data.to_a.first
    if data and data['ts']
      time_distance = Time.now.to_i - data['ts'].to_i
      @current = time_distance < @allow_distance ? data : nil
      #@current = data[1] #For test
    else
      @current = nil
    end
    @current 
  end

  def complete db, start, finish
    data = []
    if db.size > 0
      point(start, db.first["ts"].to_i, data)
      data = data + db
      point(db.last["ts"].to_i, finish, data)
    end
    data.each do |v|
      v["parent_key"] = v['ts']
    end
    data
  end

  def point start, finish, data
    if finish - start > @history_allow_distance
      start = start + @history_interval
      data.push({"ts" => start})
      point start, finish, data
    end
  end

  class << self
    def history services, options
      config = config(options[:start], options[:finish], @interval)
      start = options[:start].to_i
      finish = options[:finish].to_i
      #data = DB.multi_get(config[:family], services.collect{|s| s.uuid }, :start => start.to_s, :finish => finish.to_s, :count => 1000)
      data = config[:model].any_in(:dn => @dn).where({:ts => { "$gt" => start, "$lt" => finish }}).to_a
      data.collect!{|x|x.attributes}
      d2 = {}
      dn.each{ |x| d2[x] = [] }
      data.each do |d|
        d2[d['dn']] ||= []
        d2[d['dn']] << d
      end
      data = d2
      data
    end

    def current services
      data = DB.multi_get(:Metric, services.collect{|s| s.uuid }, :count => 1, :reversed => true)
      services.collect do |service|
        metric = service.metric
        metric.current = data[service.uuid]
        metric
      end
    end

    def config start, finish, interval, mini = false
      #起始时间在5天内，间隔小于等于2天，直接从原始数据读取    
      #起始时间在5天内，间隔大于2天，从1小时归并读取   
      #起始时间在最近30天内，任意间隔，从1小时归并读取   
      #起始时间在最近1年内，任意间距，从12小时归并读取   
      #起始时间在最近2年内，任意间距，从24小时归并读取
      now = Time.now
      far = now - start
      distance = finish - start
      family = nil
      if(far <= 5.days)
        if distance <= 2.days
          family = FAMILY[0]
          model = MODELS[0]
        else
          family = FAMILY[1]
          model = MODELS[1]
          interval = 1.hour.to_i
        end
      elsif( far <= 30.days)
        family = FAMILY[1]
        model = MODELS[1]
        interval = 1.hour.to_i
      elsif( far <= 1.year)
        family = FAMILY[2]
        model = MODELS[2]
        interval = 12.hours.to_i
      else
        family = FAMILY[3]
        model = MODELS[2]
        interval = 24.hours.to_i
      end
      {:interval => interval, :family => family, :model => model}
    end
  end
end
