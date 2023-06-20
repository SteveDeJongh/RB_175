# cms.rb

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'securerandom'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions # Enabling session support for Sinatra app.
  set :session_secret, SecureRandom.hex(32)
end

##### Helpers #####

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def render_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    erb render_markdown(content)
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = 'You must be signed in to do that.'
    redirect '/'
  end
end

# Loads appropriate YML file containing user/pass based on environment.
def load_user_credentials
  credentials_path = if ENV['RACK_ENV'] == 'test'
                       File.expand_path('../test/users.yml', __FILE__)
                     else
                       File.expand_path('../users.yml', __FILE__)
                     end
  YAML.load_file(credentials_path)
end

def credentials_path_for_yaml
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/users.yml', __FILE__)
  else
    File.expand_path('../users.yml', __FILE__)
  end
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password # Callin BCrypt#==, which returns password encrypted with the same salt.
  else
    false
  end
end

# Validate file type is supported, and has a file type.
def invalid_extension?(ext)
  valid_file_type = %w[txt md]
  valid_file_type.include?(ext)
end

##### Routes #####

# Home directory/index
get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map { |path| File.basename(path) }
  erb :index
end

# View New Document Page, placement of this route needs to be before "/:filename" to be matched first.
get '/new' do
  require_signed_in_user

  erb :new_page
end

# Create a New Document
post '/create' do
  require_signed_in_user

  filename = params[:filename].to_s
  splitfile = filename.split('.')

  if filename.size.zero? # Check file name is entered.
    session[:message] = 'Please provide a valid name.'
    status 422
    erb :new_page
  elsif !invalid_extension?(splitfile[1]) # Checks file name contains a valid extension.
    session[:message] = 'Invalid file type.'
    status 422
    erb :new_page
  else
    file_path = File.join(data_path, filename)
    File.write(file_path, '')
    session[:message] = "#{filename} has been created."
    redirect '/'
  end
end

# Sign in page
get '/users/signin' do
  erb :sign_in
end

# Submit Sign in page
post '/users/signin' do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = 'Welcome!'
    redirect '/'
  else
    session[:message] = 'Invalid credentials'
    status 422
    erb :sign_in
  end
end

# Sign up page
get '/users/signup' do
  erb :sign_up
end

# Submit Sign up page
post '/users/signup' do
  users = load_user_credentials #YAML.load(File.read("users.yml"))
  @username = params[:username]

  if users.key?(@username)
    session[:message] = "Username already exists, pelease try again."
    erb :sign_up
  else
    my_password = BCrypt::Password.create(params[:password].to_s).to_s
    users[@username] = my_password
    File.open(credentials_path_for_yaml, "w") { |file| file.write(users.to_yaml) }

    session[:message] = "#{@username} created, please sign in!"
    redirect '/'
  end
end

# Sign out
post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You have been signed out.'
  redirect '/'
end

# Deleteing a file
post '/:filename/delete' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])
  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."
  redirect '/'
end

# Duplicates a file, and renames to $NAME-copy.$ext
post '/:filename/duplicate' do
  require_signed_in_user
  split_file_name = params[:filename].split(".")
  file_name = split_file_name.insert(1, "-copy.").join('')

  file_path = data_path
  FileUtils.cp "#{File.join(data_path, params[:filename])}", "#{data_path}/#{file_name}"
  session[:message] = "#{file_name} has been created."
  redirect '/'
end

# View a files content
get '/:filename' do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

# Edit File Page
get '/:filename/edit' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)
  erb :edit_page
end

# Submit Edited File Page
post '/:filename' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content]) # Pulls content from :edit_page name field 'content'.

  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
end
