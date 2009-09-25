require 'sinatra'
require 'environment'


configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def partial(name, options={})
    haml "_#{name}".to_sym, options.merge(:layout => false)
  end
  
  def filtering_options
    [
      [
        "collection",
        {
          "Science & Health" => [
            ["aids","AIDS Campaign Posters"], 
            ["dpf99", "American Physical Society, Division of Particles and Fields"],
            ["pmtcards", "Patent Medicine trading cards"],
          ],
          
          "History" => [
            ["latimes", "LA Times photograph archive"]
          ]
        }  
      ]
    ]
  end
  
  # Returns the ceiling of the division of q by d
  # Using float is not precise enough
  def nbslices(q,d)
    divmod = q.divmod(d)
    divmod[0] + (divmod[1] > 0 ? 1 : 0)
  end
  
  class Array
    def each_slice_with_index(slice_size)
      self.enum_slice(slice_size).each_with_index { |slice,index| 
        yield slice,index
      }
    end
  end
end

# Sass stylesheet
get '/stylesheets/style.css' do
  response["Content-Type"] = "text/css; charset=utf-8" 
  sass :style
end

get '/' do
  @query = params["q"]
  @sources = params["s"] || []
  @format = params["f"]
  
  return haml(:search) if params["q"].nil? or params["q"].empty?
  return haml(:nosources) unless params["s"]
  
  if params["st"] == "panel"
    @results = CollectionReader.fetch_flat(@query, *@sources).flatten
    @nresults = @results.size
  else
    @results = CollectionReader.fetch @query, *@sources
    @nresults = @results.inject(0) { |acc,arr| acc+arr[1].size}
  end
  
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
    @style = (params["st"] && !params["st"].empty?) ? params["st"] : "grid"
    return haml("view_#{@style}".to_sym)
  end               
end

get '/test' do
  p options.haml
end