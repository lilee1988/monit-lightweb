# To change this template, choose Tools | Templates
# and open the template in the editor.

class ServiceParam < ActiveRecord::Base
  belongs_to :type, :foreign_key => 'type_id', :class_name => 'ServiceType'
  attr_accessor :value
  attr_accessor :error

  validates_presence_of :name
  validates_presence_of :alias
  validates_presence_of :param_type
  validates_presence_of :unit
  validates_presence_of :type_id

  def help
    self.desc
  end

  def validate
    @error = (required == 1 and @value.blank? ? "#{self.alias}不能为空" : nil)
  end
end
