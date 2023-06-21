# cl.rb # Contact List App

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'securerandom'
require 'yaml'

configure do
  enable :sessions # Enabling session support for Sinatra app.
  set :session_secret, SecureRandom.hex(32)
end

# Helpers #

def user_signed_in?
  session.key?(:username)
end

def load_user_credentials
  credentials_path = File.expand_path('../users.yml', __FILE__)

  YAML.load_file(credentials_path)
end

def valid_login?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    credentials[username] == password
  else
    false
  end
end

# Routes #

get '/' do
  if session.key?(:username)
    erb :index
  else
    redirect '/sign_in'
  end
end

get '/sign_in' do
  erb :sign_in
end

post '/sign_in' do
  credentials = load_user_credentials
  @username = params[:username]

  if valid_login?(@username, params[:password])
    session[:username] = @username
    session[:message] = "#{@username} has signed in."
    redirect '/'
  else
    session[:message] = 'Invalid credentials.'
    erb :sign_in
  end
end