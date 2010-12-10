class MetricType < ActiveRecord::Base
  set_table_name 'service_metrics'

  def desc_without_unit
    read_attribute(:desc) 
  end

  def desc
    u = "(" + u + ")" unless u.blank?
    s = read_attribute(:desc) 
    unless s.blank? or u.blank?
      s = s + u unless s.include? u 
    end
    s
  end
end
