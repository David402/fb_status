module RestCore
  Facebook = Builder.client do
    use DefaultSite, 'https://graph.facebook.com/'
    use DefaultHeaders, {'Accept' => 'application/json'}
    use CommonLogger, method(:puts)
    use Cache, Randle::Store.new(CONFIG['memcached_store'], compress: true), 60 do
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
    raise Error(res) if res['error']
    res
  end

  def me
    get 'me', access_token: access_token
  end

  def bbc_africa_feed
    res = get '285361880228', access_token: access_token,
              fields: 'feed.fields(message,description)'
    res['feed']['data']
  end
end
