
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
    command_name 'Minitest'
  end
end

require 'minitest/autorun'
require 'mocha/mini_test'

require 'cloud-tools'

$config_dir = File.join(File.dirname(__FILE__), "config-test")
CloudTools::Config.load
