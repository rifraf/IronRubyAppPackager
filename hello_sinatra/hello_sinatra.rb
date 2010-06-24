require 'rubygems'
require 'sinatra'

get '/hi' do
  "Hello IRPackager World!"
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
