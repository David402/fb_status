class App
  def call env
    @request = Rack::Request.new env
    case @request.request_method
    when 'GET'
      case @request.path_info
      when '/cardinal'; cardinal
      when '/blue'; blue
      else
        [200, {}, "a get request"]
      end
    when 'POST'
      [200, {}, 'a post request']
    else
      [200, {}, 'hello world']
    end
  end

  def cardinal
    name = @request.params['name']
    [200, {}, "Hi, #{name}, you're in cardinal"]
  end

  def blue
    id = @request.params['id']
    [200, {}, "Hi, user #{id}, you're in blue"]
  end
end
