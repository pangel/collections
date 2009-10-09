require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"

  # FIXME Might cause concurrency issues when multiple instances of the app are running.
  DB = RedisDB.connect
  Reader.database(DB)
  Option = Struct.new :type, :display, :items
  Options = Array.new
  Options << Option.new('collection', "Select other sources", { "History" => [["latimes", "LA Times photograph archive"]] })
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def partial(name, options={})
    haml "_#{name}".to_sym, options.merge(:layout => false)
  end

  def sources_display
    (@sources.to_a == ["latimes"] or @sources.nil?) ? "all collections" : @sources.join(', ')
  end

  def filtering_options
    Options
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

  def build_image(raw)
    raw = raw.split("|")
    collection = DB.get "collections:#{raw[0]}:name"
    collection_url =DB.get "collections:#{raw[0]}:url}"
    {:collection => collection, :collection_url => collection_url, :title => raw[1], :thumb => raw[2], :url => raw[4], :fullres_url => raw[3]}
  end
end

# Sass stylesheet
get '/stylesheets/style.css' do
  response["Content-Type"] = "text/css; charset=utf-8"
  sass :style
end

# Sass stylesheet
get '/stylesheets/style_panel.css' do
  response["Content-Type"] = "text/css; charset=utf-8"
  sass :style_panel
end

get '/' do
  @query = params["q"]
  @sources = params["s"] || ['latimes']
  @format = params["f"]

  return haml(:search) if params["q"].nil? or params["q"].empty?

  if params["st"] == "panel"
    # Panel view does not sort the results by collection
    @results = @sources.reduce([]) do |acc,source|
      acc + Reader.search(@query, source).map { |raw| build_image(raw) }
    end
    @nresults = @results.size
  else
    @nresults = 0
    @results = @sources.reduce({}) do |acc,source|
      images = Reader.search(@query, source).map { |raw| build_image(raw) }
      @nresults += images.size
      acc.merge source => images
    end
  end

  case @format
  when "xml"
    response["Content-Type"] = "text/xml; charset=utf-8"
    CollectionReader.xml(@results).to_s
  when "yaml"
    response["Content-type"] = "application/x-yaml; charset=utf-8"
    @results.to_yaml
  when "rss"
    response["Content-Type"] = "text/xml; charset=utf-8"
    @results = @sources.reduce([]) do |acc,source|
      acc + Reader.search(@query, source).map { |raw| build_image(raw) }
    end

    x = Builder::XmlMarkup.new(:indent=>2)
    x.instruct!
    x << '<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss"   xmlns:atom="http://www.w3.org/2005/Atom">'
    x.channel {
      x.title "UCLA Digital Collections Cooliris RSS feed"
      x.language "en-US"
      @results.each { |pic|
        x.item {
          x.title pic[:title]
          x.link pic[:url]
          x.media :thumbnail, {"url"=>pic[:thumb], "type" => "image/gif"}
          x.media :content, {"url"=>pic[:fullres_url], "type" => "image/jpeg"}
        }
      }
    }
    x << '</rss>'
  else
    params_minus_style = request.params.reject { |k,v| k == "st"}
    @url_minus_style = "#{request.path_info}?#{build_query(params_minus_style)}"

    params_with_rss = request.params.merge({ "f" => "rss"})
    @rss_url = "#{request.path_info}?#{build_query(params_with_rss)}"

    @style = (params["st"] && !params["st"].empty?) ? params["st"] : "grid"

    return haml(:noresults) if @results.empty?
    return haml("view_#{@style}".to_sym)
  end
end