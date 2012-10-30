require './requirements'
require './auth'
require './app'

use Rack::Static, urls: ['/css', '/img', '/favicon.ico', '/test.html'],
                  root: 'public'
use Rack::Chunked
use Rack::ContentLength
use Rack::ContentType
use Rack::Session::Cookie, secret: 'randle'
use Auth
run App.new
