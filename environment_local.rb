require 'builder'
require 'cgi'
require 'yaml'

configure do
  # Constants
  PROJECT_NAME = "collections"

  set :root, File.dirname(__FILE__)
  set :public, Proc.new { File.join(root, "public") }

  # Load extensions
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  require "loader"
  require "reader"
  require "redisdb"
end

configure :development do end