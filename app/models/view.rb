require "visualization"
class View < Visualization::Base
  set_table_name "views"
  has_many :items, :class_name => 'ViewItem', :foreign_key => 'view_id'
end
