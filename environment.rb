require 'yaml'

require 'rubygems'
require 'haml'
require 'sinatra' unless defined?(Sinatra)



configure do
  # Constants
  PROJECT_NAME = "collections"
  
  # Load extensions
  # $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  # Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| load File.basename(lib, '.*') }
  require "lib/collectionreader"
end

configure :development do end