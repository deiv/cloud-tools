
require 'yaml'

require 'cloud-tools/model.rb'

module CloudTools

class Config

  @@regions = {}
  @@instances = {}
  @@sets = {}
  @@defaults = {}
  @@credentials = {}
  @@masternode = {}

  def self.regions
    @@regions
  end

  def self.instances
    @@instances
  end

  def self.sets
    @@sets
  end

  def self.credentials
    @@credentials
  end

  def self.defaults
    @@defaults
  end

  def self.masternode
    @@masternode
  end

  def self.load
    config_file = File.join($config_dir, "instances.yml")

    unless File.exist?(config_file)
      puts "error: Unable to find the config file"
      exit 1
    end

    instances = YAML.load(File.read(config_file))

    load_struct instances[:regions], @@regions
    load_struct instances[:instances], @@instances
    load_struct instances[:sets], @@sets
    load_struct instances[:credentials], @@credentials

    @@defaults   = instances[:defaults]
    @@masternode = instances[:masternode]
  end

protected

  def self.load_struct(section, map)
    section.each do |s|
      map[s.name] = s
    end
  end
end

end
