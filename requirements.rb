APP_ROOT = File.expand_path("../", __FILE__)
CONFIG = YAML.load_file("#{APP_ROOT}/config/config.yaml")

require 'json'
require 'erb'
require 'securerandom'
require 'cgi'

require './lib/extracted_rails'
require 'rest-core'
require './lib/cache'
require './lib/rc_facebook'
require './lib/foundation'
