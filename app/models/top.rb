class Top

  FAMILY = [:Metric, :MetricRollup1, :MetricRollup12, :MetricRollup24]
  #DB = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
  attr :services

  def initialize(services, options)
    @services = services
    @options = options
    get_data
  end

  def sort(metric, n)
    data = @data
    unless metric.blank?
      if metric[0]!=45
        reverse = false
      else
        reverse = true
        metric = metric.gsub(/^\-/,"")
      end
      data.sort! do |b, a|
        (reverse ? -1 : 1)*(a[metric].to_i <=> b[metric].to_i)
      end
    end
    data = data[0, n] if n
    data
  end

  private 

  def get_data
    #每个服务大概30条数据
    options = @options
    config = self.class.config(options[:start], options[:finish])
    data = self.class.get(config[:family], @services.collect{|x|x.uuid}, :start => options[:start].to_i.to_s, :finish => options[:finish].to_i.to_s, :count => 5000)
    @data = avg_data(data)
  end

  def avg_data data
    new_data = []
    data.each do |uuid, val|
      new_val = {}
      size = val.size
      val.each do |t, da|
        da.each do |k, v|
          new_val[k] ||= 0
          new_val[k] = new_val[k] + v.to_f
        end
      end
      new_val.each do |k, v|
        new_val[k] = v/size
      end

      service = @services.select{|x| x.uuid == uuid}.first
      source = service.object
      new_val["service_id"] = service.id
      new_val["service_name"] = service.name
      type = service.object_name
      new_val[type + "_id"] = source.id
      new_val[type + "_name"] = source.name

      new_data << new_val
    end
    new_data
  end

  class << self

    def get family, uuid, options
      t1 = Time.now
      if uuid.is_a?(Array)
        data = DB.multi_get(family, uuid, options)
        size = uuid.size
        out_size = 0
        data.each{|k,v| out_size = out_size + v.size }
      else
        data = DB.get(family, uuid, options)
        size = nil
        out_size = data.size
      end
      puts "#{family} Get #{out_size}(#{(Time.now - t1)*1000}ms) #{size}#{uuid.inspect}(#{options.inspect}) "
      data
    end

    def config start, finish, interval = nil, mini = false
      #间隔<=1小时，读取未归并数据
      #间隔大于1小时小于等于24，从1小时归并读取   
      #间隔大于1天,小于7天，从12小时归并读取   
      distance = finish - start
      family = nil
      if distance <= 1.hour
        family = FAMILY[0]
      elsif distance <= 1.day
        family = FAMILY[1]
      elsif distance <= 7.day
        family = FAMILY[2]
      else
        family = FAMILY[3]
      end
      {:interval => interval, :family => family}
    end
  end
end
