#
#

Puppet::Type.newtype(:automic_deployment_target) do
  @doc = "Create a new deployment target in Automic Release Manager."
  # ... the code ...
  
  ensurable

  # define required features from the provider

  # TODO: Add validation for params
  newparam(:name, :namevar => true) do
    desc "The name of the deployment target"

    validate do |value|
      if value.strip == "" 
        raise ArgumentError, "Target name must not be empty"
      end
    end
  end

  newparam(:folder) do
    desc "The folder of the deployment target"

    validate do |value|
      if value.strip == "" 
        raise ArgumentError, "Folder must not be empty"
      end
    end
  end

  newparam(:owner) do
    desc "The owner of the deployment target"
    
    validate do |value|
      if value.strip == "" 
        raise ArgumentError, "Owner must not be empty"
      end
    end
  end

  newparam(:environment) do
    desc "The environment of the deployment target"

    #validate do |value|
    #  
    #end
  end

  newparam(:type) do
    desc "The type of the deployment target"

    validate do |value|
      if value.strip == "" 
        raise ArgumentError, "Type must not be empty"
      end
    end
  end

  newparam(:agent) do
    desc "The agent of the deployment target"

    #validate do |value|
      
    #end
  end

  # connection, properties, dynamic_properties
  newparam(:connection) do
    desc "The connection of the deployment target to RM"
  end

  newparam(:properties) do
    desc "The properties of the deployment target"
  end

  newparam(:dynamic_properties) do
    desc "The dynamic properties of the deployment target"
  end
  
end
