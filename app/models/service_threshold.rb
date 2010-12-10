# To change this template, choose Tools | Templates
# and open the template in the editor.

class ServiceThreshold < ActiveRecord::Base
  belongs_to :type, :foreign_key => 'type_id', :class_name => 'ServiceType'

  def self.operators
    [">", "<", ">=", "<=", "="]
  end
end
