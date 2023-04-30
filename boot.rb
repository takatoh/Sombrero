require "sequel"
require "yaml"

SOMBRERO_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(SOMBRERO_ROOT + "/lib")

SOMBRERO_CONFIG = YAML.load_file("config.yaml")

DB = Sequel.connect(SOMBRERO_CONFIG["database"])
