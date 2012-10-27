INDEX_VIEW = ERB.new(File.read( File.expand_path("../views/index.erb", __FILE__) ))

class App
  def call env
    @request = Rack::Request.new env
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
