class ThemesController < ApplicationController
  def index
  end

  def star
    set_tab(params[:navigation], :navigation)
    set_tab(params[:menu], :menu)
    set_tab(params[:submenu], :submenu)
    set_tab(params[:tab], :tabs)
    self.title = "Star"
    render :layout => "openstyle_star"
  end

  def ocean
    set_tab(params[:navigation], :navigation)
    set_tab(params[:menu], :menu)
    set_tab(params[:submenu], :submenu)
    set_tab(params[:tab], :tabs)
    self.title = "Ocean"
    render :layout => "openstyle_ocean"
  end

end
