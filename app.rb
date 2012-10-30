class App
  include Randle::Foundation
  def call env
    prepare_from_env env
    case @request.request_method
    when 'GET'
      case @request.path_info
      when '/'; index
      when '/home'; home
      when '/africa_news'; africa_news
      when '/facebook_callback'; get_facebook_callback
      else; [200, {}, ["a get request"]]
      end
    when 'POST'
      case @request.path_info
      when '/post_feed'; post_feed
      when '/facebook_callback'; post_facebook_callback
      else; [200, {}, ['a post request']]
      end
    else
      [200, {}, ['hello world']]
    end
  rescue RC::Facebook::Error => e
    handle_fb_error e, ['read_stream']
  end

  def index
    if env['HTTP_IF_NONE_MATCH'] and
       (UserInCache.find(uid).try(:etag) == env['HTTP_IF_NONE_MATCH'])
      [304, {}, []]
    else
      @user = @rc_facebook.me 'cache.update' => true
      erb :index
    end
  end
  def post_feed
    p = params.select{|k, v| ['message', 'link'].member?(k)}
    res = @rc_facebook.post("#{uid}/feed", p.merge(access_token: access_token))
    [200, {}, []]
  rescue RC::Facebook::Error => e
    handle_fb_error e, ['publish_stream']
  end

  def home
    @user = @rc_facebook.home
    erb :home
  end

  def africa_news
    @feed = @rc_facebook.bbc_africa_feed
    erb :africa_news
  end

  def get_facebook_callback
    params['hub.verify_token'] == 'facebookmini' ? [200, {}, [params['hub.challenge']]] : [404, {}, []]
  end

  def post_facebook_callback
    data = JSON.parse(@request.body)
    users = (data['object'] == 'user' ? data['entry'] || [])
    users.each{ |user| UserInCache.create(id: user['uid'], etag: user['time']) }
    [200, {}, []]
  end

  def handle_fb_error e, permissions
    if e.error['type'] == 'OAuthException'
      session['access_token'] = nil
      params = permissions.map{|p| "permissions[]=#{p}"}.join('&')
      return [303, {'Location' => "/login?#{params}"}, []]
    end
    raise e
  end
end
