# To change this template, choose Tools | Templates
# and open the template in the editor.

class Group < ActiveRecord::Base
  validates_presence_of :name_alias,  :parent_id
  validates_length_of   :name_alias,  :within => 3..40
  validates_format_of   :name_alias,  :with => /\A\w[\w\.\-_]+\z/, :message => "允许字母，数字以及字符.-_"
  validates_uniqueness_of   :name_alias
  has_many :sites
  has_many :apps
  has_many :devices
  has_many :hosts
  has_many :users
  before_save :gen_name
  before_destroy :valid_id


  def valid_id
    if Group.count(:conditions => "parent_id = #{id}")  > 0 or id ==1
      return false
    end
  end
  def gen_name
    old_name = name
     parent_name = Group.find(parent_id).name
     new_name = "#{parent_name}#{name_alias}/"
      if(new_name !=old_name)
        Group.update_all("name = replace(name, '#{old_name}', '#{new_name}')", "name like concat('#{old_name}','%')")
        send('name=', new_name)
    end
  end
end
