require 'rubygems'
require 'sinatra'
require 'oauthclient'
require 'zlib'
require 'stringio'
require 'json'

configure do

  # constants
  #
  Scope = 'https://www.googleapis.com/auth/buzz'
  Request_token_url = 'https://www.google.com/accounts/OAuthGetRequestToken'
  Access_token_url = 'https://www.google.com/accounts/OAuthGetAccessToken'
  Callback = 'http://www.jin.gr.jp/buzztra/access_token'
  APIbaseURL = 'https://www.googleapis.com/buzz/v1'

  # site specific info.
  # To register your site, visit https://www.google.com/accounts/ManageDomains
  # See http://code.google.com/intl/ja/apis/accounts/docs/RegistrationForWebAppsAuto.html

  require './site_info.rb'
  #Consumer_key = "your site" 
  #Consumer_secret = "himitsu"
  #Session_domain = "yourdomain"

  # Session
  #
  use Rack::Session::Cookie,
    #:key => 'rack.session',
    :domain => Session_domain,
    :path => Session_path,
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
  if session[:access_token] then
    @client.oauth_config.token = session[:access_token]
    @client.oauth_config.secret = session[:access_secret]
  end
end
  
####################################################

get '/' do
  if session[:access_token] then
    erb :index
  else
    erb :login
  end
end

get '/login' do
  erb :login
end

get '/logout' do
  erb :login
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
  secret = session[:request_token_secret]
  verifier = params[:oauth_verifier]

  res = @client.get_access_token(Access_token_url, token, secret, verifier)
  session[:request_token] = nil
  session[:access_token] = @client.oauth_config.token
  session[:access_secret] = @client.oauth_config.secret

  redirect "http://www." + Session_domain + Session_path
end


####################################################

get '/activity/*/@self/*' do
  @contents = @client.get_content(APIbaseURL +
    "/activities/" + params[:splat][0] + "/@self/", params[:splat][1],
    :alt => :json, :prettyprint => true)

  erb :contents
end

get '/activities/' do
  @contents = @client.get_content(APIbaseURL + "/activities/@me/@consumption", :alt => :json, :prettyprint => true)

  erb :contents
end

get '/activities/:name' do |id|
  if id && id.to_i > 0  then
    @contents = @client.get_content(APIbaseURL +
      "/activities/" + id.to_s + "/@public",
      :alt => :json, :prettyprint => true)
  end

  erb :contents
end

post '/search' do
  @contents = @client.get_content(APIbaseURL + "/activities/search", :alt => :json, :prettyprint => true, :q => params[:q])

  erb :contents
end

post '/activities' do
  @client.oauth_config.http_method = :post
  text =<<__END__
 { "data": {
   "object": {
     "type": "note",
     "content": "#{params[:body]}"
   } } }
__END__
  @contents = @client.post_content(APIbaseURL + "/activities/@me/@self?alt=json", text)
end

