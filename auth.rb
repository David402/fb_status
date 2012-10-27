require 'securerandom'
require 'rest-core'
require 'cgi'

class App
  def login
    if @request.params['error_reason'] or @request.params['error']
      return [200, {}, ['Why did you denied using our app?']]
    end
    code = @request.params['code']
    unless code
      @request.session['state'] = SecureRandom.hex(3)
      dialog_url = "https://www.facebook.com/dialog/oauth?client_id=" \
                   "#{APP_ID}&redirect_uri=#{CGI::escape(MY_URL)}" \
                   "&state=#{@request.session['state']}"
      return [200, {}, ["<script>top.location.href='#{dialog_url}'</script>"]]
    end
    if @request.session['state'] and @request.session['state'] == @request.params['state']
      response = RC::Universal.new.get("https://graph.facebook.com/oauth/access_token",
                                       client_id: APP_ID, redirect_uri: MY_URL,
                                       client_secret: APP_SECRET, code: code).tap{}
      @request.session['access_token'] = CGI::parse(response)['access_token'][0]
      [303, {'Location' => '/'}, []]
    else
      [200, {}, ['You are attacking our site, dude!']] # victim of CSRF
    end
  end
end
