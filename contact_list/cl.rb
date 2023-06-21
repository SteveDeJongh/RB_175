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

def data_path
  File.expand_path('../data/contacts.yml', __FILE__)
end

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

def add_contact(data, contacts)
  contacts[data[:name]] = {
    phone: [data[:phone]],
    email: [data[:email]],
    category: data[:category]
  }
  contacts
end

# Routes #

# Home page
get '/' do
  if session.key?(:username)
    @contacts = YAML.load_file(data_path)
    erb :index
  else
    redirect '/sign_in'
  end
end

# Get Sign in page
get '/sign_in' do
  erb :sign_in
end

# Submit Sign in Information
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

# Sign Out
post '/signout' do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect '/'
end

# Add Contact page
get '/addcontact' do
  erb :addcontact
end

# Add a contact
post '/addcontact' do
  @data = {name: params[:name], phone: params[:phonenumber], email: params[:email], category: params[:category]}
  contacts = YAML.load_file(data_path)
  # contacts = {"Steve"=>{:phone=>["123-456-7890"], :email=>[nil], :category=>"friend"}, "Dave"=>{:phone=>["123-123-1234"], :email=>["blah@gmail.com"], :category=>"friend"}, "test2"=>{:phone=>["test2"], :email=>["test2"], :category=>"work"}, "George"=>{:phone=>["1234567890"], :email=>["blah@yahoo.ca"], :category=>"friend"}}

  if contacts.key?(@data[:name])
    session[:message] = "Contact already exists."
  else
    session[:message] = "Contact created successfully."
    updated_contacts = add_contact(@data, contacts)

    File.open(data_path, "w") { |file| file.write(updated_contacts.to_yaml) }
    redirect '/'
  end
end

# Delete a Contact
post '/:contact/delete' do
  name = params[:contact]

  contacts = YAML.load_file(data_path)

  if contacts.key?(name)
    session[:message] = "#{name} deleted."
    contacts.delete(name)
    File.open(data_path, "w") { |file| file.write(contacts.to_yaml) }
    redirect '/'
  else
    session[:message] = "#{name} does not exist."
    erb :index
  end
end

# Detailed information page for a Contact
get '/details/:contact' do
  contacts = YAML.load_file(data_path)

  @name = params[:contact]
  @info = contacts[@name]
  erb :details
end