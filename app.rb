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
    handle_permission_error e, ['read_stream']
  end

  def index
    user = @rc_facebook.me
    feed = @rc_facebook.bbc_africa_feed
    [200, {}, [INDEX_VIEW.result(binding)]]
  end

  def post_feed
puts "!!!!!!!!!! post_feed = #{@request.params}"
    p = @request.params.select{|k, v| ['message', 'link'].member?(k)}
    @rc_facebook.post("#{@rc_facebook.me['id']}/feed",
                      p.merge(access_token: @rc_facebook.access_token))
  rescue RC::Facebook::Error => e
    handle_permission_error e, ['publish_stream']
  end

  def handle_permission_error e, permissions
    params = permissions.map{|p| "permissions[]=#{p}"}.join('&')
    if e.error['code'] == 200 and e.error['type'] == 'OAuthException'
      @request.session['access_token'] = nil
      return [303, {'Location' => "/login?#{params}"}, []]
    end
    raise e
  end
end
