#
# required gems: httpclient, savon >= 2.0
#

require 'rubygems'
require 'rexml/document'
require 'csv'
require 'savon' if Puppet.features.savon?

Puppet::Type.type(:automic_deployment_target).provide :release_manager do
  confine :feature => :savon
  
  desc "Release Manager provider to provide RM actions to deployment target type"
  
  WSDL_PATH = "/service/ImportExportService.asmx?wsdl"
  
  # check if deployment target with name resource[:name] exists or not
  def exists?
    name = @resource[:name]

    raise Puppet::Error, "Target name must not be empty!" if empty_str?(name)
    
    if @resource[:connection].nil? || @resource[:connection].empty? || empty_str?(@resource[:connection]['url'])
      raise Puppet::Error, "Connection must be a hash contains valid url, username and password to authenticate against Automic Release Manager"
    end

    client = Savon.client(wsdl: @resource[:connection]['url'] + WSDL_PATH)
    
    # try export deployment target
    begin
      message = { "username" => @resource[:connection]['username'], "password" => @resource[:connection]['password'], "mainType" => "DeploymentTarget", "format" => "CSV", "begin" => 0, "count" => 1, 
                  "properties" => { :string => "system_name" }, "conditions" => { :string => "system_name eq '#{name}'" } }
      response = client.call(:export, message: message)
      
      token = response.body[:export_response][:export_result][:token]
      self.debug("Got token: #{token}")

      # retrieve data via GetStatus service
      while true
        response = client.call(:get_status, message: { "token" => token })
        sleep 1
        if response.body[:get_status_response][:get_status_result][:status].to_i != 0
          break
        end
      end
      
      data = response.body[:get_status_response][:get_status_result][:data]
      if not data.nil? and data.lines.count > 1      
        self.info("Deployment target #{name} already exists")
        return true
      else
        self.info("No deployment target name '#{name}'")
        return false
      end
  
    rescue Exception => e
      self.info("Failed to check deployment target #{name}. We will assume that this target does not exist")
      self.debug(e.message)
      self.debug(e.backtrace.inspect)
      false
    end
  end  
  
  # create new deployment target
  def create
    name = @resource[:name]
    client = Savon.client(wsdl: @resource[:connection]['url'] + WSDL_PATH)

    environment = @resource[:environment]
    custom_props = @resource[:properties]
    dynamic_props = @resource[:dynamic_properties]

    raise Puppet::Error, "Target name, folder, owner and type must not be empty!" if empty_str?(name) or empty_str?(@resource[:folder]) or empty_str?(@resource[:owner]) or empty_str?(@resource[:type])

    self.info("Importing deployment target..")
    
    doc = REXML::Document.new '<?xml version="1.0" encoding="UTF-8"?>'
    root = doc.add_element 'Sync', { "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" }
    entity = root.add_element "Entity", { "mainType" => "DeploymentTarget", "customType" => @resource[:type] }
  
    prop_hash = { "system_name" => name, "system_owner.system_name" => @resource[:owner], "system_folder.system_name" => @resource[:folder], "system_deployment_agent_name" => @resource[:agent],
                  "system_description" => "created via Automic Puppet resource type", "system_is_active" => "true" }

    prop_hash.keys.each do |prk|
      prop_ele = entity.add_element "Property", { "name" => prk }
      if prk == 'system_name'
        prop_ele.add_attribute "isIdentity", "true"
      end
      value_ele = prop_ele.add_element "Value"
      value_ele.add_text prop_hash[prk]
    end

    if not custom_props.nil? and not custom_props.empty?
      # add custom properties
      custom_props.keys.each do |prk|
        prop_ele = entity.add_element "Property", { "name" => prk }
        value_ele = prop_ele.add_element "Value"
        value_ele.add_text custom_props[prk]
      end
    end
  
    message = { "username" => @resource[:connection]['username'], "password" => @resource[:connection]['password'], "mainType" => "DeploymentTarget", "failOnError" => true, "fomat" => "XML", "data" => doc.to_s }
    
    response = client.call(:import, message: message)

    # check error and status
    status = response.body[:import_response][:import_result][:status].to_i 
    token = response.body[:import_response][:import_result][:token]

    self.debug("Got token: #{token}")
    
    # wait for target id return in status
    while status == 0
      sleep 1
      response = client.call(:get_status, message: { "token" => token } )
      status = response.body[:get_status_response][:get_status_result][:status].to_i 
    end

    if status < 0
      self.info("Unsuccessfully create or update deployment target")
      error = response.body[:get_status_response][:get_status_result][:error]    
      if not error.nil? and not error.empty?
        self.info("Error detail: " + error.to_s)
      end
     return status
    end

    self.info("Deployment target import successfully")
    
    # add environment
    if not environment.nil? and not environment.empty?
      begin
        env_id = get_environment_id(client, environment)
        if (env_id > 0)
          add_environment_relation(client, env_id, name)
        end
      rescue Exception => e
        self.info("Error occurred while updating environment for deployment target")    
        self.debug(e.message)
        self.debug(e.backtrace.inspect)
      end
    end    

    # update dynamic properties
    if not dynamic_props.nil? and not dynamic_props.empty?
      begin
        update_dynamic_properties(client, status, dynamic_props)
      rescue Exception => e
        self.info("Error occurred while updating dynamic properties for deployment target")    
        self.debug(e.message)
        self.debug(e.backtrace.inspect)
      end
    end

    return status
  end

  #
  def destroy
    # nothing
    self.info("Nothing to destroy")
  end


  # retrives environment id from its name
  # @param client the savon client
  # @param name the target name
  def get_environment_id(client, name)

    self.info("Getting environment id from name '#{name}'")
          
    message = { "username" => @resource[:connection]['username'], "password" => @resource[:connection]['password'], "mainType" => "Environment", "format" => "CSV", "begin" => 0, "count" => 1, 
                "properties" => { :string => "system_id" }, "conditions" => { :string => "system_name eq '#{name}'" } }
    
    response = client.call(:export, message: message)
    
    token = response.body[:export_response][:export_result][:token]
    self.debug("Got token: #{token}")

    while true
      response = client.call(:get_status, message: { "token" => token })
      if response.body[:get_status_response][:get_status_result][:status].to_i != 0
        break
      end
      sleep 1
    end
    
    self.debug("Get Status SOAP response: " + response.to_s)
    
    data = response.body[:get_status_response][:get_status_result][:data]
    
    if data.nil? or data.lines.count < 2
      self.info("Environment not found: #{name}. Skip environment import.")
      return -1
    end

    env_id = data.split("\n")[1].split(",")[-1]
    return env_id.to_i
  end

  # add environment relation to target
  # @param client the savon client
  # @param env_id the environment id
  # @param name the target name
  def add_environment_relation(client, env_id, name)

    self.info("Adding environment relation to target'#{name}'..")

    # add environment relation to target
    csv_string = CSV.generate do |csv|
      csv << ["system_environment.system_id", "system_deployment_target.system_name"]
      csv << [env_id, name]
    end

    message = { "username" => @resource[:connection]['username'], "password" => @resource[:connection]['password'], "mainType" => "EnvironmentDeploymentTargetRelation", "failOnError" => true, "fomat" => "CSV", "data" => csv_string}
    response = client.call(:import, message: message)

    status = response.body[:import_response][:import_result][:status].to_i 
    
    token = response.body[:import_response][:import_result][:token]

    self.debug("Got token: #{token}")
    
    #while status == 0
    #  sleep 1
    #  response = client.call(:get_status, message: { "token" => token } )
    #  status = response.body[:get_status_response][:get_status_result][:status].to_i 
    #end

    error = response.body[:import_response][:import_result][:error]    

    if status < 0
      self.info("Unsuccessfully add environment id #{env_id} to target #{name}")
      if not error.nil? and not error.empty?
        self.info("Error detail: " + error.to_s)
      end
      return
    end
    
    self.info("Environment update finished")
  end

  # update dynamic properties of given target
  # @param client the savon client
  # @param target_id the target id
  # @param dynamic_props dynamic properties hash
  def update_dynamic_properties(client, target_id, dynamic_props)
      
    self.info("Updating dynamic properties for target #{target_id} ..")
  
    doc = REXML::Document.new '<?xml version="1.0" encoding="UTF-8"?>'
    root = doc.add_element 'Sync', { "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" }
    dynamic_props.keys.each do |dpk|
      next if dpk.nil? or dpk.empty?
      dyn_property = dpk.to_s
      dpk_props = dynamic_props[dpk]
      type = dpk_props['type']
      type = (type.nil? or type.empty?) ? "SingleLineText" : type
      fullname = dpk_props['namespace']
      fullname = "/" + fullname unless fullname.start_with?("/")
      if fullname.end_with?("/") 
        fullname = fullname + dyn_property
      else
        fullname = fullname + "/" + dyn_property
      end
      
      self.info("Updating dynamic property #{fullname} to \"#{dpk_props['value']}\"")
      prop_hash = { "system_on_entity.system_id" => "#{target_id}", "system_on_maintype" => "DeploymentTarget", "system_full_name" =>  fullname, "system_type" => type }
      prop_hash['system_value'] = dpk_props['value'] if dpk_props['value']
      prop_hash['system_description'] = dpk_props['description']

      entity = root.add_element "Entity", { "mainType" => "DynamicProperty" }
      prop_hash.keys.each do |prk|
        prop_ele = entity.add_element "Property", { "name" => prk }
        if prk == 'system_full_name' or prk == 'system_on_entity.system_id' or prk == 'system_on_maintype'
          prop_ele.add_attribute "isIdentity", "true"
        end
        value_ele = prop_ele.add_element "Value"
        value_ele.add_text prop_hash[prk]
      end
    end
  
    # "fomat" is intended, this is a typo mistake from RM Data API
    message = { "username" => @resource[:connection]['username'], "password" => @resource[:connection]['password'], "mainType" => "DynamicProperty", "failOnError" => false, "fomat" => "XML", "data" => doc.to_s }
    
    response = client.call(:import, message: message)

    # check error and status
    status = response.body[:import_response][:import_result][:status].to_i 
    token = response.body[:import_response][:import_result][:token]

    self.debug("Got token: #{token}")
    
    if status < 0
      self.info("Unsuccessfully update dynamic property for target #{target_id}")
      error = response.body[:import_response][:import_result][:error]    
      if not error.nil? and not error.empty?
        self.info("Error detail: " + error.to_s)
      end
      return
    end
    
    self.info("Dynamic properties update finished")
  end

  def empty_str?(str)
    return true if str.nil? or str.empty? or str.strip == ""
    false
  end

end
