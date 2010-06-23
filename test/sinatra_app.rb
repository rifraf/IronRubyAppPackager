require 'rubygems'
require 'sinatra'

get '/hi' do
  "Hello Vendored World!"
end

get '/' do
  redirect '/index.html'
end

get '/index' do
  redirect '/index.html'
end

get '/exit' do
  exit!(0)
end

if defined?(Vendorize)
  Vendorize.add_dir('sinatra')
  Vendorize.add_dir('public')
end

# If 'public' has been copied into the embedded resources then
# static files will get served up from there fine. If you want
# them to load from disk instead, you need to tell Sinatra
# where to look:
#if defined?(SERFS)
#  set :public, 'public'
#end
