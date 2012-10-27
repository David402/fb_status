require './app'

use Rack::ContentType
use Rack::ContentLength
use Rack::Static, urls: ['/css', '/img'], root: 'public'
use Rack::Session::Cookie, secret: 'randle'
run App.new
