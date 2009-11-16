require 'builder'
require 'cgi'
require 'yaml'

configure do
  # Constants
  PROJECT_NAME = "collections"

  set :root, File.dirname(__FILE__)
  set :public, Proc.new { File.join(root, "public") }
end

configure :development do end