require 'json'
require 'erb'

require './auth'

APP_ID='521199414574024'
APP_SECRET='1e80afa96c9bb2b8f00872145c520188'
MY_URL='http://fb-status.herokuapp.com/'

INDEX_VIEW = ERB.new(File.read( File.expand_path("../views/index.erb", __FILE__) ))

class App
  def call env
    @request = Rack::Request.new env
    return login if @request.request_method == 'GET' and @request.path_info == '/login'
    [303, {'Location' => "/login"}, []] unless @request.params['access_token']

    case @request.request_method
    when 'GET'
      case @request.path_info
      when '/'; index
      else
        [200, {}, ["a get request"]]
      end
    when 'POST'
      [200, {}, ['a post request']]
    else
      [200, {}, ['hello world']]
    end
  end

  def index
    user = JSON.parse(RC::Universal.new.get('https://graph.facebook.com/me',
                                            access_token: @request.session['access_token']))
    [200, {}, [INDEX_VIEW.result(binding)]]
  end
end
