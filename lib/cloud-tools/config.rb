
require 'yaml'

require 'cloud-tools/model.rb'

module CloudTools

class Config

  @@regions = {}
  @@instances = {}
  @@recipes = {}
  @@defaults = {}
  @@credentials = {}
  @@masternode = {}

  def self.regions
    @@regions
  end

  def self.instances
    @@instances
  end

  def self.recipes
    @@recipes
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
    config_file = File.join($config_dir, "config.yml")

    unless File.exist?(config_file)
      puts "error: Unable to find the config file"
      exit 1
    end

    config = YAML.load(File.read(config_file))

    load_struct config[:regions], @@regions
    load_struct config[:instances], @@instances
    load_struct config[:credentials], @@credentials

    @@defaults   = config[:defaults]
    @@masternode = config[:masternode]

    cookbook_dir = File.join($config_dir, "cookbook")

    @@recipes = Hash[
      Dir["#{cookbook_dir}/*.recipe"].map do |path|
         [File.basename(path, File.extname(path)), path]
      end
    ]
  end

protected

  def self.load_struct(section, map)
    section.each do |s|
      map[s.name] = s
    end
  end
end

end
