# cms.rb

require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "securerandom"

configure do
  enable :sessions # Enabling session support for Sinatra app.
  set :session_secret, SecureRandom.hex(32)
end

root = File.expand_path("..", __FILE__)

get "/" do
  @files = Dir.glob(root + "/data/*").map { |path| File.basename(path) }
  erb :index
end

get "/:filename" do
  file_path = root + "/data/" + params[:filename]

  if File.file?(file_path)  
    headers["Content-Type"] = "text/plain" # Setting content type header response.
    File.read(file_path)    
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end
