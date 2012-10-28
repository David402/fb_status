CONFIG = YAML.load_file( File.expand_path("../config/config.yaml", __FILE__) )

require 'json'
require 'erb'
require 'securerandom'
require 'cgi'

require './lib/extracted_rails'
require 'rest-core'
require './lib/cache'
require './lib/rc_facebook'
