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
      else; [200, {}, ["a get request"]]
      end
    when 'POST'
      case @request.path_info
      when '/post_feed'; post_feed
      else; [200, {}, ['a post request']]
      end
    else
      [200, {}, ['hello world']]
    end
  rescue RC::Facebook::Error => e
    handle_fb_permission_error e, ['read_stream']
  end

  def index
    etag = UserInCache.find(uid).try(:etag)
    headers = etag ? {'ETag' => etag} : {}
    if env['HTTP_IF_NONE_MATCH'] and (etag == env['HTTP_IF_NONE_MATCH']) and
       session['post_feed_msg'].empty?
      [304, headers, []]
    else
      @msg = "'#{session['post_feed_msg']}'"
      session['post_feed_msg'] = nil
      @user = @rc_facebook.me 'cache.update' => true
      [200, headers, [erb(:index)]]
    end
  end
  def post_feed
    p = params.select{|k, v| ['message', 'link'].member?(k)}
    res = @rc_facebook.post("#{uid}/feed", p.merge(access_token: access_token))
    [200, {}, []]
  rescue RC::Facebook::Error => e
    handle_fb_permission_error e, ['publish_stream'], post_feed_msg: params['message']
  end

  def home
    @user = @rc_facebook.home
    [200, {}, [erb(:home)]]
  end

  def africa_news
    @feed = @rc_facebook.bbc_africa_feed
    [200, {}, [erb(:africa_news)]]
  end

  def handle_fb_permission_error e, permissions, opts={}
    if e.error['type'] == 'OAuthException'
      session['access_token'] = nil;
      session['post_feed_msg'] = opts[:post_feed_msg]
      params = permissions.map{|p| "permissions[]=#{p}"}.join('&')
      return [303, {'Location' => "/login?#{params}"}, []]
    end
    raise e
  end
end
