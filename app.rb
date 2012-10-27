require 'securerandom'
require 'cgi'
require 'json'
require 'rest-core'

APP_ID='521199414574024'
APP_SECRET='1e80afa96c9bb2b8f00872145c520188'
MY_URL='http://fb-status.herokuapp.com'

class App
  def call env
    @request = Rack::Request.new env
    case @request.request_method
    when 'GET'
      case @request.path_info
      when '/'; index
      else
        [200, {}, "a get request"]
      end
    when 'POST'
      [200, {}, 'a post request']
    else
      [200, {}, 'hello world']
    end
  end

  def index
    if @request.params['error_reason'] or @request.params['error']
      [200, {}, ['Why did you denied using our app?']]
    end
    code = @request.params['code']
    unless code
      @request.session['state'] = SecureRandom.hex(3)
      dialog_url = "https://www.facebook.com/dialog/oauth?client_id=" \
                   "#{APP_ID}&redirect_uri=#{CGI::escape(MY_URL)}" \
                   "&state=#{@request.session['state']}"
      return [200, {}, ["<script>top.location.href='#{dialog_url}'</script>"]]
    end
    if @request.session['state'] and @request.session['state'] == @request.params['state']
      token_url = "https://graph.facebook.com/oauth/access_token?" \
                  "client_id=#{APP_ID}&redirect_uri=#{CGI::escape(MY_URL)}" \
                  "&client_secret=#{APP_SECRET}&code=#{code}"
      response = RC::Universal.new.get(token_url).tap{}
      @request.session['access_token'] = CGI::parse(response['access_token'])

      user = JSON.parse(RC::Universal.new.get('https://graph.facebook.com/me',
                                              access_token: @request.session['access_token']))
      [200, {}, ["Hi, #{user['name']}, your facebook id is #{user['id']}"]]
    else
      [200, {}, ['You are attacking our site, dude!']] # victim of CSRF
    end
  end
end
