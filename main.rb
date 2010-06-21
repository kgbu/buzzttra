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

def base_url
  "http://www." + Session_domain + Session_path
end
  
####################################################
# authentication
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

  redirect base_url
end


####################################################
# Resource access 
####################################################

##
#	activities
#
get '/activity/*/@self/*' do
  @contents = @client.get_content(APIbaseURL +
    "/activities/" + params[:splat][0] + "/@self/", params[:splat][1],
    :alt => :json, :prettyprint => true)

  erb :contents
end

get '/activities/' do
  @contents = @client.get_content(APIbaseURL + "/activities/@me/@consumption",
    :alt => :json, :prettyprint => true)

  erb :contents
end

get '/activities/get/:name' do |id|
  if id && id.to_i > 0  then
    @contents = @client.get_content(APIbaseURL + "/activities/" + id.to_s + "/@public",
      :alt => :json, :prettyprint => true)
  end

  erb :jscontents
end

post '/search' do
  @contents = @client.get_content(APIbaseURL + "/activities/search",
    :alt => :json, :prettyprint => true, :q => params[:q])

  erb :contents
end

post '/activities' do
  @client.oauth_config.http_method = :post
  body =<<__END__
 { "data": {
   "object": {
     "type": "note",
     "content": "#{params[:body]}"
   } } }
__END__
  extheader = { "Content-Type" => "application/json" }
  @contents = @client.post_content(APIbaseURL + "/activities/@me/@self?alt=json", body, extheader)

  if @contents
    redirect base_url
  else
    @contents 
  end
end

get '/activities/delete' do
  @contents = @client.delete(APIbaseURL + "/activities/@me/@self/#{params[:id]}")
  redirect base_url
end

get '/activities/like' do
  @contents = @client.put(APIbaseURL + "/activities/@me/@liked/#{params[:id]}")
  redirect base_url
end

get '/activities/unlike' do
  @contents = @client.delete(APIbaseURL + "/activities/@me/@liked/#{params[:id]}")
  redirect base_url
end

get '/activities/mute' do
  @contents = @client.put(APIbaseURL + "/activities/@me/@muted/#{params[:id]}")
  redirect base_url
end

get '/activities/unmute' do
  @contents = @client.delete(APIbaseURL + "/activities/@me/@muted/#{params[:id]}")
  redirect base_url
end

get '/activities/abuse' do
  @contents = @client.put(APIbaseURL + "/activities/@me/@abuse/#{params[:id]}")
  redirect base_url
end

##
#	comments
#
get '/activities/@me/@self/*/@comments' do
  @contents = @client.get_content(APIbaseURL +
    "/activities/@me/@self/"+ params[:splat][0] + "/@comments",
    :alt => :json, :prettyprint => true)

  erb :contents
end

get '/activities/@me/@self/*/@comments/*' do
  @contents = @client.get_content(APIbaseURL +
    "/activities/@me/@self/"+ params[:splat][0] + "/@comments/" + params[:splat][1],
    :alt => :json, :prettyprint => true)

  erb :contents
end

post '/activities/@me/@self/@comments' do
  body =<<__END__
 { "data": {
   "object": {
     "content": "#{params[:body]}"
   } } }
__END__
  extheader = { "Content-Type" => "application/json" }
  @contents = @client.post_content(APIbaseURL +
    "/activities/@me/@self/"+ params[:splat][0] + "/@comments?alt=json", body, extheader)

  redirect base_url
end

post '/activities/@me/@self/@comments' do
  body =<<__END__
 { "data": {
   "object": {
     "content": "#{params[:body]}"
   } } }
__END__
  extheader = { "Content-Type" => "application/json" }
  @contents = @client.post_content(APIbaseURL +
    "/activities/@me/@self/"+ params[:id] + "/@comments?alt=json", body, extheader)

  redirect base_url
end

get '/activities/@me/@self/*/@comments/*' do
  @contents = @client.get_content(APIbaseURL +
    "/activities/@me/@self/"+ params[:splat][0] + "/@comments/" + params[:splat][1],
    :alt => :json, :prettyprint => true)

  erb :contents
end

get '/activities/comments/delete/' do
  @contents = @client.delete(APIbaseURL + "/activities/@me/@self/#{params[:activityid]}/@comments/#{params[:commentid]}")
  redirect base_url
end
