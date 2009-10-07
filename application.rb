require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"

  # FIXME Might cause concurrency issues when multiple instances of the app are running.
  DB = RedisDB.connect

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
  @sources = params["s"]
  @format = params["f"]

  return haml(:search) if params["q"].nil? or params["q"].empty?

  @results = Reader.database(DB).search(@query, @sources)


  if params["st"] == "panel"
    @results = @results.map { |k,v|
      (v && v.map { |raw| build_image(raw) })
    }.flatten.compact
    @nresults = @results.size
  else
    @results.each do |k,v|
        @results[k] = v.map { |raw| build_image(raw) } unless v.nil?
      end
    @nresults = @results.inject(0) { |acc,arr| acc + (arr[1].nil? ? 0 : arr[1].size)}
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
    @results = @results.map { |k,v|
      v.map { |raw| build_image(raw) }
    }.flatten

    x = Builder::XmlMarkup.new(:indent=>2)
    x.instruct!
    x << '<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss"   xmlns:atom="http://www.w3.org/2005/Atom">'
    x.channel {
      x.title "UCLA!"
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

    return haml(:noresults) if @results.first.nil?
    return haml("view_#{@style}".to_sym)
  end
end