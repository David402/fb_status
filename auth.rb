class Auth
  LOGIN_URL='http://fb-mini.herokuapp.com/login'
  READ_PERMISSIONS=['read_stream']
  def initialize app; @app = app; end
  def call env
    @request = Rack::Request.new env
    return @app.call(env) if session['access_token'] and session['uid']
    res = case @request.request_method
          when 'GET'
            case @request.path_info
            when '/login'; login
            when '/facebook_callback'; get_facebook_callback
            end
          when 'POST'
            case @request.path_info
            when '/facebook_callback'; post_facebook_callback
            end
          end
    res || [303, {'Location' => '/login'}, []]
  end

  def login
    return [200, {}, ['Why did you denied using our app?']] if params['error_reason']
    code = params['code']
    unless code
      session['state'] = SecureRandom.hex(3)
      permissions = params['permissions'] || READ_PERMISSIONS
      dialog_url = "https://www.facebook.com/dialog/oauth?client_id=" \
                   "#{CONFIG['facebook_app_id']}&redirect_uri=#{CGI::escape(LOGIN_URL)}" \
                   "&state=#{session['state']}&scope=#{permissions.join(',')}"
      return [200, {}, ["<script>top.location.href='#{dialog_url}'</script>"]]
    end
    if session['state'] and session['state'] == params['state']
      response = RC::Universal.new.get("https://graph.facebook.com/oauth/access_token",
                                       client_id: CONFIG['facebook_app_id'], redirect_uri: LOGIN_URL,
                                       client_secret: CONFIG['facebook_app_secret'], code: code).tap{}
      session['access_token'] = CGI::parse(response)['access_token'][0]
      session['uid'] = RC::Facebook.new.get('me', access_token: session['access_token'])['id']
      UserInCache.create(id: session['uid'], etag: 1)
      [303, {'Location' => '/'}, []]
    else
      [200, {}, ['You are attacking our site, dude!']] # victim of CSRF
    end
  end

  def get_facebook_callback
    params['hub.verify_token'] == 'facebookmini' ? [200, {}, [params['hub.challenge']]] : [404, {}, []]
  end

  def post_facebook_callback
    data = JSON.load(@request.body)
puts "post_facebook_callback: data = #{data}"
    users = (data['object'] == 'user' ? data['entry'] : [])
    users.each{ |user| UserInCache.create(id: user['uid'], etag: user['time']) }
    [200, {}, []]
  end

  def session
    @request.session
  end

  def params
    @request.params
  end
end
