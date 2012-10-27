#require 'json'
require 'erb'
#require 'securerandom'
require 'cgi'

require 'rest-core'

require './auth'
require './app'

use Rack::ContentType
use Rack::ContentLength
use Rack::Static, urls: ['/css', '/img', '/favicon.ico', '/test.html'],
                  root: 'public'
use Rack::Session::Cookie, secret: 'randle'
use Auth
run App.new
