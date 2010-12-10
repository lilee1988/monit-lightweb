class StatusView
  FAMILY = [:Status, :StatusRollup1, :StatusRollup12, :StatusRollup24]
  #DB = Cassandra.new("Monit", CASSANDRA_CONFIG["default"]["servers"])
  SERVICE_TEMP = {"ok" => 0, "warning" => 0, "unknown" => 0, "critical" => 0}
  HOST_TEMP = {"up" => 0, "down" => 0}
  SERVICE_STATUS = ["ok", "warning", "unknown", "critical"]
  HOST_STATUS = ["up", "down"]
  STATUS_KEY = ["ok", "warning", "unknown", "critical", "up", "down"]
  MODELS = [Status, StatusHourly, StatusDaily]

  attr :object

  def initialize(object)
    @object = object
    @uuid = @object.uuid
    @dn = @object.dn
    @history_cache = {}
    @total_cache = {}
  end

  def total options
    key = get_key(options)
    return @total_cache[key] if @total_cache.has_key?(key)
    data = history(options)
    if @object.is_a?(Service)
      status = SERVICE_TEMP.dup
    else
      status = HOST_TEMP.dup
    end
    data.each do |val|
      status.each do |k, v|
        status[k] = val[k].to_i + status[k]
      end
    end
    @total_cache[key] = self.class.to_percent(status)
  end

  def total_view options, is_chart = false
    model = @object.class
    view = View.new(:name => "#{@object.name}的状态", :dimensionality => 2, :enable => 1, :template => is_chart ? "ampie" : "status", :height => 300, :width => "100%")
    if model == Service
      status = SERVICE_STATUS 
    else
      status = HOST_STATUS 
    end
    model_name = model.name.downcase
    status.each do |k|
      view.items << ViewItem.new(:name => "_" + k, :color => model.status_colors[model.status.index(k)], :alias => I18n.t("status.#{model_name}.#{k}"), :data_type => "float", :data_unit => "%")
    end
    view.data = total(options)
    view
  end

  def history options
    start = options[:start].to_i
    finish = options[:finish].to_i
    key = get_key(options)
    return @history_cache[key] if @history_cache.has_key?(key)

    config = self.class.config(options[:start], options[:finish])
    data = self.class.get(config[:model], @dn, :start => start.to_s, :finish => finish.to_s, :count => 1000)
    set_history data, options
  end

  def set_history data, options
    key = get_key(options)
    @history_cache[key] = handle(data)
  end

  def history_view options, is_chart = false
    model = @object.class
    view = View.new(:name => "#{@object.name}的状态", :dimensionality => 3, :enable => 1, :template => is_chart ? "amcolumn_stacked" : "datagrid", :height => 300, :width => "100%")
    if model == Service
      status = SERVICE_STATUS 
    else
      status = HOST_STATUS 
    end
    model_name = model.name.downcase
    pa = {:name => "parent_key", :alias => "时间", :data_type => "datetime", :data_format => "time"} 
    view.items << ViewItem.new(pa)
    status.each do |k|
      view.items << ViewItem.new(:name => "_" + k, :color => model.status_colors[model.status.index(k)], :alias => I18n.t("status.#{model_name}.#{k}"), :data_type => "float", :data_unit => "%")
    end
    #data_array = []
    #history(options).each do |k, v|
    #  v["parent_key"] = k
    #  data_array << v
    #end
    view.data = history(options)
    view
  end

  private 

  def get_key options
    "C#{options[:start].to_i}_#{options[:finish].to_i}"
  end

  def handle data
    data.collect! do |val|
      val['parent_key'] = val['ts']
      #val.each do |k, v|
      #  val[k] = v.to_i
      #end
      unless @object.is_a?(Service)
        val = self.class.to_host(val)
      end
      self.class.to_percent(val)
    end
    data
  end

  class << self

    def get model, dn, options
      t1 = Time.now
      if dn.is_a?(Array)
        #data = DB.multi_get(model, dn, options)
        data = model.any_in({:dn => dn }).where({:ts => { "$gt" => options.start.to_i, "$lt" => options.finish.to_i }}).to_a
        data.collect!{|x|x.attributes}
        d2 = {}
        dn.each{ |x| d2[x] = [] }
        data.each do |d|
          d2[d['dn']] ||= []
          d2[d['dn']] << d
        end
        data = d2
      else
        #data = DB.get(model, dn, options)
        data = model.where({:dn => dn, :ts => { "$gt" => options.start.to_i, "$lt" => options.finish.to_i }}).to_a
        data.collect!{|x|x.attributes}
      end
      #puts "#{model} Get (#{(Time.now - t1)*1000}ms) #{dn.inspect}(#{options.inspect}) "
      data
    end

    def history objects, options
      if objects.length>0
        config = config(options[:start], options[:finish])
        data = get(config[:model], objects.collect{|s| s.dn }, :start => options[:start].to_i.to_s, :finish => options[:finish].to_i.to_s, :count => 5000)
        data.each do |dn, val|
          objects.select{|x| x.dn == dn}.each{|o|o.status_data.set_history(val, options)}
        end
        objects.collect{|x| x.status_data}
      end
    end

    def view model, status_data, options, is_chart = false
      view = View.new(:name => "#{model.human_name}状态", :dimensionality => 3, :enable => 1, :template => is_chart ? "amcolumn_stacked" : "datagrid", :height => 330, :width => "100%")
      if model == Service
        status = SERVICE_STATUS 
      else
        status = HOST_STATUS 
      end
      model_name = model.name.downcase
      pa = {:name => model_name, :alias => model.human_name, :data_type => "string"} 
      unless is_chart
        pa.update(:data_format => "link", :data_format_params => "href=#{options[:show_url]}")
      end
      view.items << ViewItem.new(pa)
      status.each do |k|
        view.items << ViewItem.new(:name => "_" + k, :color => model.status_colors[model.status.index(k)], :alias => I18n.t("status.#{model_name}.#{k}"), :data_type => "float", :data_unit => "%")
      end
      unless is_chart
        view.items << ViewItem.new(:name => "more", :alias => "&nbsp;", :data_type => "string", :data_format => "link", :data_format_params => "href=#{options[:more_url]}")
      end
      view.data = status_data.collect do |st|
        d = st.total options
        d[model_name] = is_chart ? st.object.name.mb_chars[0..10] : st.object.name
        d["id"] = st.object.id
        d["more"] = "查看详细"
        d
      end
      view
    end

    #def host_view data
    #  data = tr({"ok" => "up", "warning" => "up", "unknown" => "down", "critical" => "down"}, data)
    #  view = View.new(:name => "状态", :dimensionality => 2, :enable => 1, :template => "status")
    #  data.each do |k, v|
    #    view.items << ViewItem.new(:name => k, :color => Host.status_colors[Host.status.index(k)], :alias => I18n.t("status.host.#{k}"), :data_type => "int")
    #  end
    #  view.data = data
    #  view
    #end

    def to_host data
      tr({"ok" => "up", "warning" => "up", "unknown" => "down", "critical" => "down"}, data)
    end

    def to_percent data
      total = 0
      data.each do |k, v|
        total = total + v if STATUS_KEY.include?(k)
      end
      new = {}
      data.each do |k, v|
        new["_" + k] = total > 0 ? (v.to_f/total).round(3)*100 : 0 if k[0] != 95 if STATUS_KEY.include?(k)
      end
      new.each do |k, v|
        data[k] = v
      end
      data
    end

    def tr config, data
      new = data.class.new
      config.each do |k, v|
        new[v] ||= 0
        new[v] = new[v] + data[k].to_i
      end
      new
    end

    def config start, finish, interval = nil, mini = false
      #间隔<=1天，从1小时归并读取   
      #间隔大于1天小于等于7天，从12小时归并读取   
      #间隔大于7天，从24小时归并读取   
      distance = finish - start
      family = nil
      model = MODELS[0]
      if distance <= 1.days
        family = FAMILY[1]
        model = MODELS[1]
      elsif distance <= 7.days
        family = FAMILY[2]
        model = MODELS[2]
      else
        family = FAMILY[3]
        model = MODELS[2]
      end
      {:interval => interval, :family => family, :model => model}
    end
  end
end
