require 'rubygems'
require 'sinatra'
require 'oauthclient'
require 'zlib'
require 'stringio'

configure do
  Consumer_key = "www.jin.gr.jp" 
  Consumer_secret = "1wsMBGB+QjfwFWFfbG4I/Se5"

  Scope = 'https://www.googleapis.com/auth/buzz'
  Request_token_url = 'https://www.google.com/accounts/OAuthGetRequestToken'
  Access_token_url = 'https://www.google.com/accounts/OAuthGetAccessToken'
  Callback = 'http://www.jin.gr.jp/buzztra/access_token'


  # Session
  use Rack::Session::Cookie,
    #:key => 'rack.session',
    :domain => 'jin.gr.jp',
    :path => '/buzztra',
    :expire_after => 3600,
    :secret => Digest::SHA1.hexdigest(rand.to_s)

end

before do
  unless @client
  @client = OAuthClient.new
  @client.oauth_config.consumer_key = Consumer_key
  @client.oauth_config.consumer_secret = Consumer_secret
  @client.oauth_config.signature_method = 'HMAC-SHA1'
  @client.oauth_config.http_method = :get
  @client.debug_dev = STDERR if $DEBUG
  end
end
  
def base_url
  default_port = (request.scheme == "http") ? 80 : 443
  port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
  "#{request.scheme}://#{request.host}#{port}"
  "http://www.jin.gr.jp/buzztra"
end


get '/' do
  erb %{ 
  <a href="/buzztra/request_token">OAuth Login</a>
  <a href="/buzztra/activities">Activities</a>
  }
end

get '/login' do
  "#{base_url} Hello World!"
end


get '/activities' do
# Access to a protected resource.
# @consumption requires Buzz API
content = @client.get_content("https://www.googleapis.com/buzz/v1/activities/@me/@consumption", :alt => :json, :prettyprint => true)
  erb %{ <%= content %> }
end

get '/logout' do
end

get '/request_token' do
  # Get request token.
  res = @client.get_request_token(Request_token_url, Callback, :scope => Scope)
  token = res.oauth_params['oauth_token']
  secret = res.oauth_params['oauth_token_secret']
  raise if token.nil? or secret.nil?

  session[:request_token] = token
  session[:request_token_secret] = secret
  
  # You need to confirm authorization
  redirect "https://www.google.com/buzz/api/auth/OAuthAuthorizeToken?oauth_token=#{token}&domain=#{Consumer_key}&scope=#{Scope}&btmpl=mobile"

end


get '/access_token' do
  token = params[:oauth_token]
  session[:request_token] = token
  secret = session[:request_token_secret]
  verifier = params[:oauth_verifier]

  res = @client.get_access_token(Access_token_url, token, secret, verifier)
  session[:user_id] = res.oauth_params['user_id']
  content = @client.get_content("https://www.googleapis.com/buzz/v1/activities/@me/@consumption", :alt => :json, :prettyprint => true)
  erb %{ <%= p res %> }
end
