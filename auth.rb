class Auth
  LOGIN_URL='http://fb-status.herokuapp.com/login'
  READ_PERMISSIONS=['read_stream']
  def initialize app; @app = app; end
  def call env
    @request = Rack::Request.new env
    return @app.call(env) if @request.session['access_token']
    return login if @request.path_info == '/login'
    [303, {'Location' => '/login'}, []]
  end

  def login
    permissions = @request.params['permissions'] || READ_PERMISSIONS
    if @request.params['error_reason'] or @request.params['error']
      return [200, {}, ['Why did you denied using our app?']]
    end
    code = @request.params['code']
    unless code
      @request.session['state'] = SecureRandom.hex(3)
      dialog_url = "https://www.facebook.com/dialog/oauth?client_id=" \
                   "#{CONFIG['facebook_app_id']}&redirect_uri=#{CGI::escape(LOGIN_URL)}" \
                   "&state=#{@request.session['state']}&scope=#{permissions.join(',')}"
      return [303, {'Location' => dialog}, []]
      #return [200, {}, ["<script>top.location.href='#{dialog_url}'</script>"]]
    end
    if @request.session['state'] and @request.session['state'] == @request.params['state']
      response = RC::Universal.new.get("https://graph.facebook.com/oauth/access_token",
                                       client_id: CONFIG['facebook_app_id'], redirect_uri: LOGIN_URL,
                                       client_secret: CONFIG['facebook_app_secret'], code: code).tap{}
      @request.session['access_token'] = CGI::parse(response)['access_token'][0]
      [303, {'Location' => '/'}, []]
    else
      [200, {}, ['You are attacking our site, dude!']] # victim of CSRF
    end
  end
end
