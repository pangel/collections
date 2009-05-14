require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

helpers do end

# Sass stylesheet
get '/stylesheets/style.css' do
  response["Content-Type"] = "text/css; charset=utf-8" 
  sass :style
end

get '/' do
  return haml(:search) unless params["q"]
  
  query = params["q"]
  sources = params["s"]
  format = params["f"]
  
  results = CollectionReader.fetch query, *sources
  
  case format
  when "xml"
    response["Content-Type"] = "text/xml; charset=utf-8" 
    CollectionReader.xml(results).to_s
  when "yaml"
    response["Content-type"] = "application/x-yaml; charset=utf-8"
    results.to_yaml
  else
    return haml(:view,:locals=>{:results=>results})
  end               
end
# 
# get %r{/(.*)/(.*)} do |sources,req|
#   query, format = req.split "."
#   sources = sources.split "+"
#   
#   respond_types = { "xml" =>  lambda { |r| r.to_xml},
#                     "json" => lambda { |r| error(404, "sorry no json")},
#                     "yaml" => lambda { |r| r.to_yaml},
#                     "html" => lambda { |r| haml(:view,:locals=>{:results=>results})}
#                   }
#                   
#   unless respond_types.keys.include? format
#     query = "#{query}.#{format}"
#     format = "html"
#   end
#   
#   results = CollectionReader.fetch query, *sources
#   
#   respond_types[format].call(results)
#   
# end