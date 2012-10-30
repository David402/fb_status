module RestCore
  Facebook = Builder.client do
    use DefaultSite, 'https://graph.facebook.com/'
    use DefaultHeaders, {'Accept' => 'application/json'}
    use CommonLogger, method(:puts)
    use Cache, MEMCACHED_STORE, 60 do
      use JsonResponse, true
    end
  end
end

class RC::Facebook
  attr_accessor :access_token
  class Error < RuntimeError
    attr_accessor :error
    def initialize error={}
      self.error = error
      super(error.inspect)
    end
  end
  def get path, query={}, opts={}
    res = super(path, query, opts)
    raise Error.new(res['error']) if res['error']
    res
  end
  def post path, payload={}, query={}, opts={}
    res = super(path, payload, query, opts)
    raise Error.new(res['error']) if res['error']
    res
  end

  def me opts={}
    get('me', {access_token: @access_token,
               fields: 'name,picture,feed.limit(3).fields(caption,description,message,likes)'}, opts)
  end

  def home
    # app_2915120374 is 'Status Updates' application in fql
    # SELECT filter_key, name, type, value FROM stream_filter WHERE uid=100000437300099
    get('me', {access_token: @access_token,
               fields: 'picture,name,home.filter(app_2915120374).' \
                       'fields(from,to,with_tags,message,type)'})
  end

  def bbc_africa_feed
    res = get '285361880228', access_token: @access_token,
              fields: 'feed.fields(message,description)'
    res['feed']['data']
  end
end
