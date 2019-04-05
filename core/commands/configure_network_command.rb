# (0_о) 
require_relative '../models/network_config_file'

class ConfigureNetworkCommand
  def self.publicKeysSsh(args)
    #pwd = Dir.pwd
  
    raise 'Configuration name is required' if args.nil?
  
    args = args.split('/')
    
    congig = NetworkConfigFile.new(args[0]+'_network_config')
    p congig
    
    exit_code = 0 
    
  end
end