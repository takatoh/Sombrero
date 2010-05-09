require 'rubygems'
require 'sequel'
require 'yaml'

unless defined?(PC_ROOT)
  PC_ROOT = File.dirname(__FILE__)
  $LOAD_PATH.unshift(PC_ROOT + "/lib")
end

PC_CONFIG = YAML.load_file("config.yaml") unless defined?(PC_CONFIG)

DB = Sequel.connect(PC_CONFIG["database"]) unless defined?(DB)


