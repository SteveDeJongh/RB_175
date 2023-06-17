# cms.rb

require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "securerandom"
require "redcarpet"

configure do
  enable :sessions # Enabling session support for Sinatra app.
  set :session_secret, SecureRandom.hex(32)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def render_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

# Home directory/index
get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map { |path| File.basename(path) }
  erb :index
end

# View a files content
get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
     load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Edit File Page
get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit_page
end

# Submit Edited File Page
post "/:filename" do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content]) # Pulls content from :edit_page name field "content".

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end
