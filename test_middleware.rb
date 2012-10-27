class TestMiddleware
  def initialize app, company_name
    @app, @company_name = app, company_name
  end

  def call env
    status, headers, body = @app.call(env)
    [status, headers, ["#{body}, by #{@company_name}, RACK_ENV: #{ENV['RACK_ENV']}"]]
  end
end
