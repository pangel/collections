require 'builder'
require 'cgi'

require 'rubygems'
require 'haml'
require 'sinatra' unless defined?(Sinatra)

configure do
  # Constants
  PROJECT_NAME = "collections"

  # Load extensions
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  require "loader"
  require "reader"
  require "redisdb"
end

configure :development do end