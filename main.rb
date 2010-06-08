require 'rubygems'
require 'sinatra'
require 'oauthclient'
require 'zlib'
require 'stringio'

configure do
  KEY = "www.jin.gr.jp" 
  SECRET = "1wsMBGB+QjfwFWFfbG4I/Se5"

  SCOPE = 'https://www.googleapis.com/auth/buzz'
  Request_token_url = 'https://www.google.com/accounts/OAuthGetRequestToken'
  Access_token_url = 'https://www.google.com/accounts/OAuthGetAccessToken'


  # Session
  use Rack::Session::Cookie,
    #:key => 'rack.session',
    :domain => 'jin.gr.jp',
    :path => '/buzztra',
    :expire_after => 3600,
    :secret => Digest::SHA1.hexdigest(rand.to_s)

end

def base_url
  default_port = (request.scheme == "http") ? 80 : 443
  port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
  "#{request.scheme}://#{request.host}#{port}"
  "http://www.jin.gr.jp/buzztra"
end


get '/' do
  erb %{ <a href="/buzztra/request_token">OAuth Login</a> }
end

get '/login' do
  "#{base_url} Hello World!"

end


get '/logout' do
end

get '/request_token' do
callback = 'http://www.jin.gr.jp/buzztra/access_token'
client = OAuthClient.new
client.oauth_config.consumer_key = KEY
client.oauth_config.consumer_secret = SECRET
client.oauth_config.signature_method = 'HMAC-SHA1'
client.oauth_config.http_method = :get
client.debug_dev = STDERR if $DEBUG

# Get request token.
res = client.get_request_token(Request_token_url, callback, :scope => SCOPE)
token = res.oauth_params['oauth_token']
secret = res.oauth_params['oauth_token_secret']
raise if token.nil? or secret.nil?
  session[:request_token] = token
  session[:request_token_secret] = secret
  redirect request_token.authorize_url
end


get '/access_token' do
  request_token = OAuth::RequestToken.new(
    oauth_consumer, session[:request_token], session[:request_token_secret])
end
