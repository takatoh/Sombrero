require 'rubygems'
require 'sequel'
require 'sequel/extensions/migration'

require 'boot'


Sequel::Migrator.apply(DB, './db/migration')

