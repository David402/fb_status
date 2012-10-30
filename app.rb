class App
  include Randle::Foundation
  def call env
    @request = Rack::Request.new env
    @rc_facebook = RC::Facebook.new
    @rc_facebook.access_token = @request.session['access_token']
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
    handle_fb_error e, ['read_stream']
  end

  def index
    me_clear_cache = @request.session['me_clear_cache']
    @request.session['me_clear_cache'] = nil if me_clear_cache
    user = @rc_facebook.me 'cache.update' => me_clear_cache
    erb :index
  end

  def post_feed
    p = @request.params.select{|k, v| ['message', 'link'].member?(k)}
    res = @rc_facebook.post("#{@rc_facebook.me['id']}/feed",
                            p.merge(access_token: @rc_facebook.access_token))
    @request.session['me_clear_cache'] = true
    [200, {}, []]
  rescue RC::Facebook::Error => e
    handle_fb_error e, ['publish_stream']
  end

  def home
    user = @rc_facebook.home
    erb :home
  end

  def africa_news
    feed = @rc_facebook.bbc_africa_feed
    erb :africa_news
  end

  def handle_fb_error e, permissions
    if e.error['type'] == 'OAuthException'
      @request.session['access_token'] = nil
      params = permissions.map{|p| "permissions[]=#{p}"}.join('&')
      return [303, {'Location' => "/login?#{params}"}, []]
    end
    raise e
  end
end
