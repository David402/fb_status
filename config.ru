require './test_middleware'
require './app'

use Rack::ContentType
use Rack::ContentLength
use TestMiddleware, 'PicCollage'
run App.new
