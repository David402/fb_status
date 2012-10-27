INDEX_VIEW = ERB.new(File.read( File.expand_path("../views/index.erb", __FILE__) ))

class App
  def call env
    @request = Rack::Request.new env
    @rc_facebook = RC::Facebook.new
    @rc_facebook.access_token = @request.session['access_token']
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
    user = @rc_facebook.me
    feed = @rc_facebook.bbc_africa_feed
    [200, {}, [INDEX_VIEW.result(binding)]]
  end
end
