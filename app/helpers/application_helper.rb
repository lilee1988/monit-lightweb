module ApplicationHelper
  def remote_signup_url
    "http://www.chinaccnet.com/reg.php?club=monit"
  end

  def remote_login_url
    "http://www.chinaccnet.com/login.php?goto_page=http://www.chinaccnet.com/monit.php"
  end

  def format_time time, new_line = false
    if time
      if time.year == Time.now.year
        str = l(time, :format => :short)
      else
        str = l(time, :format => :long)
      end
      new_line ? raw(str.gsub(/\s/,'<br />')) : str
    else
      nil
    end
  end

  def add_tag url, options = {}, &block
    options[:class] = "last"
    content_tag(:div, content_tag(:span, content_tag(:span, link_to(t("add"), url, options, &block))), :class => "ui-actions actions")
  end

  def icon_status type, status
    icon_tag "#{type}-#{status}", :title => t("status.#{type}.#{status}")
  end

  def status_tabs options, selected = nil, html_options = {}
    add_class_to_options 'status-tabs ul', html_options
    n = 1
    len = options.size
    list = '<li class="first"><span>&nbsp;<em>&nbsp;</em></span></li>'
    options.each do |a|
      cl = a[0]
      #cl += ' first' if n == 1
      #cl += ' last' if n == len
      cl += ' current' if a[0] == selected
      if a[2] == 0
        cl += ' disabled' 
        content = content_tag 'span', raw(a[1]) + content_tag('em', a[2])
      else
        content = link_to raw(a[1]) + content_tag('em', a[2]), a[3]
      end
      list << content_tag('li', content, :class => cl)
      n = n + 1
    end
    list << '<li class="last"><span>&nbsp;<em>&nbsp;</em></span></li>'
    content_tag 'ul', raw(list), html_options

  end

  def amcharts_tag(type, size, data, settings, options = {})
    defauts = { 
      :width => "400",
      :height             => "300",
      :swf_path           => "/amcharts",
      :flash_version      => "8",
      :background_color   => "#FFFFFF",
      :preloader_color    => "#000000",
      :express_install    => true,
      :id                 => "amcharts#{[].object_id}",
      :help               => "To see this page properly, you need to upgrade your Flash Player",
      :size => size
    }
    if settings.is_a? Hash
      defauts[:settings_file] = url_for(settings) 
    else
      defauts[:chart_settings] = settings.gsub(/\s*\n\s*|<!--.*?-->/, "").gsub(/>\s+</,"><").gsub("'","\\'") unless settings.blank?
    end
    if data.is_a? Hash
      defauts[:data_file] = url_for(data) 
    else
      unless data.blank?
        defauts[:chart_data] = data.gsub(/\s*\n\s*/, "\\n").gsub("'","\\'") 
      end
    end
    options = defauts.merge(options)
    if size = options.delete(:size)
      options[:width], options[:height] = size.split("x") #if size =~ %r{^\d+x\d+$}
    end

    script = "var so = new SWFObject('#{options[:swf_path]}/am#{type}.swf', " + "'swf_#{options[:id]}', '#{options[:width]}', '#{options[:height]}', " + "'#{options[:flash_version]}', '#{options[:background_color]}');"
    script << "so.addVariable('path', '#{options[:swf_path]}/');"
    script << "so.useExpressInstall('#{options[:swf_path]}/expressinstall.swf');" if options[:express_install]
    script << add_variable(options, :settings_file)
    script << add_variable(options, :chart_settings)
    script << add_variable(options, :additional_chart_settings)
    script << add_variable(options, :data_file)
    script << add_variable(options, :chart_data)
    script << add_variable(options, :preloader_color)
    script << add_swf_params(options, :swf_params)
    script << "so.write('#{options[:id]}');"
    content_tag('div', options[:help], :id => options[:id]) + javascript_tag(script)
  end

  def filter_params options = {}, update = {}
    options = options.dup
    options.delete :sort
    options.delete :page
    options.delete :action
    options.delete :controller
    options.update update
    options
  end


  private
  # Add variable to swfobject
  def add_variable(options, key, escape=true)
    return "" unless options[key]
    stresc = options[key]
    val = escape ? "encodeURIComponent('#{stresc}')" : "'#{stresc}'"
    "so.addVariable('#{key}', #{val});"
  end

  # Add parameters in params[key] to SWFObject
  def add_swf_params(options, key, escape=false)
    return "" unless options[key]
    res = ""
    options[key].each_pair do |key, val|
      stresc = val
      val = escape ? "escape('#{stresc}')" : "'#{stresc}'"
      res << "so.addParam('#{key}', #{val});"
    end
    res
  end



end
