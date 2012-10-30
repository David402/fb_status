require 'singleton'

class Erb
  include Singleton
  def initialize
    @views = {}
  end
  def erb v
    @views[v] ||= ERB.new(File.read("#{APP_ROOT}/views/#{v}.erb"))
  end
end

module Randle; end
module Randle::Foundation
  def erb v
    Erb.instance.erb(v).result(binding)
  end

  def session
    @request.session
  end

  def params
    @request.params
  end

  def prepare_from_env env
    @request = Rack::Request.new env
    @rc_facebook = RC::Facebook.new
    @rc_facebook.access_token = @request.session['access_token']
    @env = env
  end

  def access_token
    @request.session['access_token']
  end

  def uid
    @request.session['uid']
  end

  def env
    @env
  end
end
