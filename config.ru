$LOAD_PATH << File.expand_path(".")
require 'rubygems'
require 'bundler'
Bundler.setup
Bundler.require

require './app'

class App < Sinatra::Base
  set :public_folder, "public"
  set :views, "views"
  set :vagrant_root, File.expand_path("~/VirtualBox\ VMs")
end

map '/assets' do
   environment = Sprockets::Environment.new
   environment.append_path './javascripts'
   environment.append_path './stylesheets'
   run environment
end

map '/' do
   run App
end

