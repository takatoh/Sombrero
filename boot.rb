require 'rubygems'
require 'sequel'
require 'yaml'

unless defined?(SOMBRERO_ROOT)
  SOMBRERO_ROOT = File.dirname(__FILE__)
  $LOAD_PATH.unshift(SOMBRERO_ROOT + "/lib")
end

SOMBRERO_CONFIG = YAML.load_file("config.yaml") unless defined?(SOMBRERO_CONFIG)

DB = Sequel.connect(SOMBRERO_CONFIG["database"]) unless defined?(DB)


