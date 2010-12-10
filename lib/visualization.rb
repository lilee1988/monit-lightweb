module ::Visualization

  class Base < ActiveRecord::Base

    attr_accessor :data_url

    def data=(d)
      case self.dimensionality
      when 3
        d = [d] unless d.is_a?(Array)
        @rows = Rows.new(d)
      when 2
        @rows = Row.new(d)
      else
      end
      @data = d
    end

    def data
      @data
    end

    def normalize_data
      self.rows.normalize(self.columns.data_normalize)
    end

    def format_data
      self.rows.format self.columns.data_format
    end

    def show_unit
      self.rows.show_unit self.columns.data_unit
    end

    def filter_data
      case self.dimensionality
      when 2
        new = Row.new
        self.columns.each do |col|
          new[col.human_name.to_sym] = @rows[col.name.to_sym]
        end
        @rows = new
      when 3
        @rows = self.rows.filter(:select => self.columns.names)
      end
    end

    def rows
      @rows
    end

    def columns
      @columns || (@columns = Columns.new(items))
    end

    def data_params
      str = read_attribute(:data_params)
      Rack::Utils.parse_query(str).symbolize_keys
    end

    def data_params=(val)
      ar = data_params
      val.each do |k, v|
        ar[k.to_sym] = v
      end
      write_attribute :data_params, Rack::Utils.unescape(ar.to_param)
    end

    GOOGLE_DATA_TYPE_TO = {:string => "string", :float => "number", :int => "number", :boolean => "boolean", :date => "date", :datetime => "datetime"}

    def to_google_data_table name = "data"
      str = "var #{name} = new google.visualization.DataTable();\n"
      case self.dimensionality
      when 2
        str << "#{name}.addColumn('string','label');\n"
        str << "#{name}.addColumn('number','value');\n"
      when 3
        self.columns.each do |col|
          str << "#{name}.addColumn('#{GOOGLE_DATA_TYPE_TO[col.data_type]}','#{col.human_name}');\n"
        end
      end
      str << "#{name}.addRows(#{rows.to_a.to_json});\n"
    end

    def inspect
      #"#<#{self.class} #{to_s}>"
      super
    end

    private
    def t_data d
      if d
        ret = []
        self.columns.each do |col|
          ret << [col.human_name, d[col.name] || d[col.name.to_sym]]
        end
      else
        ret nil
      end
      ret
    end
  end

  class Normalize
    VALID_DATA_TYPE = ["string", "float", "int", "date", "datetime", "boolean"]
    class << self
      def data data, type
        case type
        when :int
          data = data.blank? ? nil : data.to_i
        when :float
          data = data.blank? ? nil : data.to_f.round(2)
        when :datetime
          if data.is_a?(Integer) or (data.is_a?(String) and data.size == 10)
            data = Time.at(data.to_i)
          elsif data.is_a?(String)
            data = Time.parse(data)
          end
        when :boolean
          data = !(["false", "", "0"].include?(data))
        else
          data = data.to_s
        end
        data
      end
    end
  end

  class Format
    VALID_PATTERN_OPTIONS = [:content]
    VALID_LINK_OPTIONS = [:href, :content]
    class << self

      def params data, ob
	ob = ob.dup
        ob.each do |k, v|
          if v =~ /^\$\{([^\}]+)\}$/
            ob[k] = data[v[2..-2].to_sym]
          else
            ob[k] = ob[k].gsub(/\$\{([^\}]+)\}/){ |s| data[s[2..-2].to_sym] } if ob[k]
          end
        end
      end

      def time data, options
        data.is_a?(Time) ? I18n.l(data, :format => :short) : data
      end

      def pattern data, options
        options.assert_valid_keys(VALID_PATTERN_OPTIONS)
        options[:content]
      end

      def kb_to_gb data, options
        self.div data, 1000*1000
      end

      def kb_to_mb data, options
        self.div data, 1000
      end

      def byte_to_kb data, options
        self.div data, 1000
      end

      def byte_to_mb data, options
        self.div data, 1000*1000
      end

      def byte_to_gb data, options
        self.div data, 1000*1000*1000
      end

      def link(data, options = {})
        options.assert_valid_keys(VALID_LINK_OPTIONS)
        "<a href='#{options[:href]}'>#{data}</a>"
      end

      #private
      def div numerator, denominator
        numerator.nil? ? nil : (numerator.to_f/denominator).round(2)
      end
    end
  end

  class Columns < Array

    attr_reader :names

    def initialize(items = nil)
      items = [items] unless items.is_a?(Array)
      push *items
    end

    def names
      collect { |x| x[:name] }.join(",")
    end

    def data_normalize
      collect { |x| [x[:name].to_sym, x.data_type] }
    end

    def data_format
      (select {|col| col.data_format }).collect{ |col| [col[:name].to_sym, col.data_format, col.data_format_params] }

    end

    def data_unit
      (select {|col| col.data_unit }).collect{ |col| [col[:name].to_sym, col.data_unit] }
    end

    def push *args
      args.collect! { |x| child(x) }
      super
    end

    def unshift *args
      args.collect! { |x| child(x) }
      super
    end

    def []=(index, obj)
      obj = child(obj)
      super
    end

    def << (obj)
      obj = child obj
      super
    end

    def inspect
      "#<#{self.class} #{names} #{super}>"
    end

    private

    def child obj
      Column.new obj
    end
  end

  class Column < Hash

    def initialize(item = nil)
      super(nil)
      case item
      when self.class
        return item
      when Hash
        item.each {|k,v| self[k] = v}
      when ActiveRecord::Base
        item.class.column_names.each {|k| self[k.to_sym] = item[k.to_sym]}
      else
      end
    end

    def human_name=(name)
      @human_name = name
    end

    def method_missing name, *args
      self[:name]
    end

    def human_name
      @human_name || self[:alias]
    end

    def data_type
      Normalize::VALID_DATA_TYPE.include?(self[:data_type]) ? self[:data_type].to_sym : :string
    end

    def data_unit
      self[:data_unit]
    end

    def data_format
      f = self[:data_format].blank? ? nil : self[:data_format].to_sym
      f = Format.method(f) if f and Format.respond_to?(f)
      f
    end

    def data_format_params
      Rack::Utils.parse_query(self[:data_format_params]).symbolize_keys
    end

    def inspect
      "#<#{self.class} #{super}>"
    end
  end

  #Rows wrapper mybe  Array, Hash, OrderedHash
  #
  #For example
  #
  #Array:
  # data = [[1, 2, 3], [2, 4, 5], [3, 2, 3]]
  # data = [["yahoo", "google", "microsoft"], ["facebook", "twitter", "dig"]]
  #
  #Hash, OrderedHash:
  # data = {"12233" => [1, 2, 3], "23424" => [2, 4, 5]}
  #

  class Rows < Array

    def initialize(data = [])
      case data
      when Array
        push *data
      else
      end
    end

    def normalize *args
      each do |v|
        v.normalize *args
      end
    end

    def format *args
      each do |v|
        v.format *args
      end
    end

    def show_unit *args
      each do |v|
        v.show_unit *args
      end
    end

    VALID_FILTER_OPTIONS = [:limit, :offset, :reverse, :step, :select]
    def filter(options)
      options.assert_valid_keys(VALID_FILTER_OPTIONS)
      da = self.class.new
      each do |v|
        da.push v.filter(options)
      end
      da
    end

    alias_method :select, :filter

    def to_s sep = "\n", child_sep = ","
      collect{|x| x.to_s(sep, child_sep, false)}.join(sep)
    end

    def to_a
      collect{ |x| x.to_a(false) }
    end

    def push *args
      args.collect! { |x| child(x) }
      super
    end

    def unshift *args
      args.collect! { |x| child(x) }
      super
    end

    def []=(index, obj)
      obj = child(obj)
      super
    end

    def << (obj)
      obj = child obj
      super
    end

    def inspect
      "#<#{self.class} #{super}>"
    end

    private

    def child obj
      Row.new obj
    end

  end

  class Row < ActiveSupport::OrderedHash

    #Row mybe  Array, Hash, OrderedHash, ActiveRecord::Base
    #
    #For example
    #
    #Array:
    # data = [1, 2, 3]
    #
    #Hash, OrderedHash:
    # data = { "l1" => 1, "l2" => 2, "l3" => 3 }
    #
    #ActiveRecord::Base
    #
    # data = #<Service id: 34>
    #

    def initialize(data = [])
      super(nil)
      case data
      when Array
        data.each_index do |k|
          self[k.to_s.to_sym] = data[k]
        end
      when Hash
        data.each do |k, v|
          self[k.to_sym] = v
        end
      when ActiveRecord::Base
        data.class.column_names.each do |k|
          k = k.to_sym
          self[k] = data[k]
        end
      else
      end
    end

    def normalize col, type = :string
      if col.is_a? Array
        col.each { |c| normalize *c }
      else
        self[col] = Normalize.data(self[col], type)
      end
    end

    def show_unit col, unit = ""
      if col.is_a? Array
        col.each { |c| show_unit *c }
      else
        #Don't show unit when data is null.
        self[col] = "#{self[col]}#{unit}" if self[col]
      end
    end

    def format col, method = nil, params = {}
      if col.is_a? Array
        col.each { |c| format *c }
      else
        #self[col] = Format.data(self, content)
        self[col] = method.call(self[col], Format.params(self, params)) if method
      end
    end

    def filter options
      select = options[:select]
      select = (select.is_a?(String) ? select.strip.split(/[\s,]+/) : []).uniq
      return self if select.size == 0
      da = self.class.new
      select.each do |s|
        s = s.strip.to_sym
        da[s] = self[s]
      end
      da
    end

    def to_s sep="\n", child_sep = ",", include_key = true
      (include_key ? to_a.collect{|x| x.join(child_sep)}.join(sep) : values.join(child_sep))
    end

    def inspect
      "#<#{self.class} #{super.scan(/\{.*\}/).to_s}>"
    end

  end
end
