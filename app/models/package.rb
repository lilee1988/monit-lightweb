class Package < ActiveRecord::Base

  def title
    "#{human_category_name}(#{name})"
  end

  def category_name
    category && self.class.category[category] ? self.class.category[category] : 'free'
  end

  def human_category_name
    I18n.t("package_category.#{category_name}")
  end

  def css_name
    ["yellow", "blue", "green"][category]
  end

  class << self

    def category
      ['free', 'standard', 'enterprise']
    end

    def defaults
      [{:category=>0,:name=>"免费",:max_services=>"6",:max_hosts=>1,:charge=>0},
        {:category=>1,:name=>"5监控器",:max_services=>"50",:max_hosts=>5,:charge=>49},
        {:category=>1,:name=>"10监控器",:max_services=>"100",:max_hosts=>10,:charge=>88},
        {:category=>1,:name=>"20监控器",:max_services=>"200",:max_hosts=>20,:charge=>168},
        {:category=>2,:name=>"10监控器",:max_services=>"200",:max_hosts=>10,:charge=>198},
        {:category=>2,:name=>"25监控器",:max_services=>"500",:max_hosts=>25,:charge=>468},
        {:category=>2,:name=>"50监控器",:max_services=>"1000",:max_hosts=>50,:charge=>858}]
    end
  end
end
