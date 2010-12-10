class PNGenerator

  #Example: 
  # tokens: "| (> a 1) (>= b2 3.2) (< bs 23)"
  # array: ["|", [">", "a", "1"], [">=", "b2", "3.2"], ["<", "bs", "23"]]
  # scan: "| (> a 1) (>= b2 3.2) (< bs 23)".scan(/[a-z|A-Z|0-9|\.]+|\>=|\<=|[\>\<=\&\|\(\)]/)
  #
  @@RE_SCAN = /[a-z|A-Z|0-9|_|\.]+|\>=|\<=|[\>\<=\&\|\(\)\!]/ 
    @@OPERATOR = ['&', '|', '!']
  @@COMPARE_OPERATOR = ['>', '>=', '<', '<=', '=']

  attr :array

  def initialize ob
    if ob.is_a? String
      @array = parse scan(ob)
    elsif ob.is_a? Array
      ob.collect! do |x|
        x = "0" if x.blank?
        x
      end
      @array = parse ob
    else
      @array = nil
    end
  end

  def valid?
    validate @array
  end

  def to_s
    valid? ? serialise(@array, true) : nil
  end

  private

  def validate  ar
    if ar.is_a? Array
      ar = ar.dup
      key = ar.shift
      pass = key && ((@@COMPARE_OPERATOR.include?(key) && ar.size == 2) || (@@OPERATOR.include?(key) && ar.size >= 2))
      ar.each do |k|
        pass = false unless validate(k)
      end
      pass
    elsif ar.is_a? String
      return true
    else
      return false
    end
  end

  def serialise ar, first = false, str = ""
    if ar.is_a? Array
      ar = ar.dup
      str = ar.shift + " "
      ar.collect! do |h|
        serialise(h)
      end
      str << ar.join(" ")
      str = "(" + str + ")" unless first
      str
    elsif ar.is_a? String
      ar
    else
      ""
    end
  end

  def parse ar
    ar = ar.collect do |x|
      x = '"' + x + '"' unless '()'.include? x
      x
    end
    ar = ar.join(',').gsub(/\(,/,'[').gsub(/,\)/,']')
    ar = "[" + ar + "]" unless ar.first == "["
    begin
      ar = eval ar
    rescue SyntaxError
      ar = nil
    end
    ar
  end

  def scan str
    str.scan @@RE_SCAN
  end

  class << self

    def operator
      @@OPERATOR
    end

    def compare_operator
      @@COMPARE_OPERATOR
    end

  end

end
