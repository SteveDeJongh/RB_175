# app.rb
require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @documents = Dir.glob("public/*").map {|file| File.basename(file) }.sort
  @documents.reverse! if params[:sort] == "desc"
  erb :list
end