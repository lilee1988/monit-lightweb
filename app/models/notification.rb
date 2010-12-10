class Notification < ActiveRecord::Base
  TYPES = [{:id => 1, :name => "alert"}, {:id => 2, :name => "report"}]
  @@methods = [{:id => 0, :name => "email", :title => "邮件"}]
  cattr_reader :methods
  belongs_to :user

  def method_name
    @@methods[method][:name]
  end

  def human_method_name
    @@methods[method][:title]
  end
end

