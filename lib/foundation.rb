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
    [200, {}, [Erb.instance.erb(v).result(binding)]]
  end
end
