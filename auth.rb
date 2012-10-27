APP_ID='521199414574024'
APP_SECRET='1e80afa96c9bb2b8f00872145c520188'
LOGIN_URL='http://fb-status.herokuapp.com/login'

class Auth
  def initialize app; @app = app; end
  def call env
    @request = Rack::Request.new env
    return @app.call(env) if @request.session['access_token']
    return login if @request.path_info == '/login'
    [303, {'Location' => '/login'}, []]
  end

  def login
    puts "session: #{@request.session['state']}, params: #{@request.params['state']}"

    if @request.params['error_reason'] or @request.params['error']
      return [200, {}, ['Why did you denied using our app?']]
    end
    code = @request.params['code']
    unless code
      @request.session['state'] = SecureRandom.hex(3)
      dialog_url = "https://www.facebook.com/dialog/oauth?client_id=" \
                   "#{APP_ID}&redirect_uri=#{CGI::escape(LOGIN_URL)}" \
                   "&state=#{@request.session['state']}"
      return [200, {}, ["<script>top.location.href='#{dialog_url}'</script>"]]
    end
    if @request.session['state'] and @request.session['state'] == @request.params['state']
      response = RC::Universal.new.get("https://graph.facebook.com/oauth/access_token",
                                       client_id: APP_ID, redirect_uri: LOGIN_URL,
                                       client_secret: APP_SECRET, code: code).tap{}
      @request.session['access_token'] = CGI::parse(response)['access_token'][0]
      [303, {'Location' => '/'}, []]
    else
      [200, {}, ['You are attacking our site, dude!']] # victim of CSRF
    end
  end
end
