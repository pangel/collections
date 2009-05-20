require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

helpers do
  def partial(name, options={})
    haml name, options.merge(:layout => false)
  end
end

# Sass stylesheet
get '/stylesheets/style.css' do
  response["Content-Type"] = "text/css; charset=utf-8" 
  sass :style
end

get '/' do
  return haml(:search) if params["q"].nil? or params["q"].empty?
  return haml(:nosources) unless params["s"]
  
  @query = params["q"]
  @sources = params["s"]
  @format = params["f"]
  
  @results = CollectionReader.fetch @query, *@sources
  
  case @format
  when "xml"
    response["Content-Type"] = "text/xml; charset=utf-8" 
    CollectionReader.xml(@results).to_s
  when "yaml"
    response["Content-type"] = "application/x-yaml; charset=utf-8"
    @results.to_yaml
  else
    params_minus_style = request.params.reject { |k,v| k == "st"}
    @url_minus_style = "#{request.path_info}?#{build_query(params_minus_style)}"
    @style = params["st"] || "grid"
    return haml("view_#{@style}".to_sym)
  end               
end

get '/test' do
  haml request.params.reject { |k,v| k == "salut" }.inspect
end