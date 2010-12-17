class ServicesController < ApplicationController
  # GET /services
  # GET /services.xml
  before_filter :find_object

  def index
    @services = Service.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @services }
    end
  end

  # GET /services/1
  # GET /services/1.xml
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service }
    end
  end

  def types
    if @object.is_a?(Site)
      @service_types = ServiceType.all(:conditions => "object_type = 3")
    else
      @service_types = @object.type.service_types
    end
  end

  # GET /services/new
  # GET /services/new.xml
  def new
    @service = Service.new(:type_id => params[:type_id], :check_interval => 300)
    type = @service.type
    unless type
      redirect_to polymorphic_path([@object, Service], :action => "types") and return
    end

    dictionary
    @service.object_id = @object.id
    @service.name = type.default_name
    @service.threshold_critical = type.threshold_critical
    @service.threshold_warning = type.threshold_warning
    @service.check_interval = type.check_interval

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @service }
    end
  end

  # GET /services/1/edit
  def edit

    dictionary
  end

  # POST /services
  # POST /services.xml
  def create
    @service = @object.services.new(params[:service])
    @service.tenant_id = current_tenant.id
    @service.location = "hz"

    respond_to do |format|
      if @service.save
        format.html { redirect_to(polymorphic_path([@object, @service]), :notice => "#{@service.name}创建成功。") }
        format.xml  { render :xml => @service, :status => :created, :location => @service }
      else
        dictionary
        format.html { render :action => "new" }
        format.xml  { render :xml => @service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /services/1
  # PUT /services/1.xml
  def update
    @service.tenant_id = current_tenant.id
    respond_to do |format|
      if @service.update_attributes(params[:service])
        format.html { redirect_to(polymorphic_path([@object, @service]), :notice => "#{@service.name}更新成功。") }
        format.xml  { head :ok }
      else
        dictionary
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.xml
  def destroy
    @service.destroy

    respond_to do |format|
      format.html { redirect_to(@object) }
      format.xml  { head :ok }
    end
  end

  private

  def dictionary
    #@object_type = @service_type.object_type
    #@object = @app || @site || @host || @device
    #@type_name = @object_type == 1 ? '主机' : '应用'
    set_check_intervals
  end

  def set_check_intervals
    @check_intervals = Service::CHECK_INTERVALS
    #@check_intervals = [["选择采集频度", ""]] + Service::CHECK_INTERVALS
    #@default_check_interval = @service_type.check_interval
  end

  def find_object
    op = {:conditions => {:tenant_id => current_tenant.id}}
    @service = Service.find(params[:id], op) unless params[:id].blank?
    if @service
      @object = @service.object
    else
      @site = Site.find(params[:site_id], op) unless params[:site_id].blank?
      @app = App.find(params[:app_id], op) unless params[:app_id].blank?
      @host = Host.find(params[:host_id], op) unless params[:host_id].blank?
      @object = @site || @app || @host
    end
    set_tab(@object.class.name.tableize.to_sym, :menu) if @object
  end
end
