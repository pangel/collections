require 'sinatra'
require 'environment'
require 'lib/helpers'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"

  COLLECTIONS = YAML.load_file("collections.yaml")

  Option = Struct.new :type, :display, :items
  Options = Array.new
  Options << Option.new('collection', "Select other sources", COLLECTIONS.group_by { |k,v| v["category"] })
end

helpers do
  include Rack::Utils
  include Helpers
  alias_method :h, :escape_html
  alias_method :hj, :escape_javascript

  def partial(name, options={})
    haml "_#{name}".to_sym, options.merge(:layout => false)
  end

  def normalize(results)
    results.map do |e|
      collection = COLLECTIONS[e["projectId"]]
      {
        :title          => hj(e["title"]),
        :collection     => hj(collection["name"]),
        :collection_url => hj(collection["url"]),
        :url            => hj("http://digital2.library.ucla.edu/viewItem.do?ark=" + e["ark"]),
        :fullres_url    => hj("http://digital2.library.ucla.edu/imageResize.do?scaleFactor=1&contentFileId=" + e["submasterFileId"]),
        :thumb          => hj(e["thumbnailURL"])
      }
    end
  end

  def in_sources?(source_id)
    if @sources
      @sources.include? source_id
    else
      false
    end
  end

  def filtering_options
    Options
  end

  def search(query,sources)
    # HTTParty's URI params normalizer does not allow repetition of a parameter, so we use our own.
    params = sources.map { |s| "selectedProjects=#{s}" }
    params  << "keyWord=#{CGI::escape(query)}"
    response = HTTParty.get "http://digital2.library.ucla.edu/testAjax.do", :query => params.join('&'), :format => :json
    normalize response
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

# Sass stylesheet
get '/stylesheets/style_panel.css' do
  response["Content-Type"] = "text/css; charset=utf-8"
  sass :style_panel
end

get '/rss/:sources/:query' do
  @query = params['query']
  @sources = params['sources'].split(' ')
  @results = search @query, @sources

  response["Content-Type"] = "text/xml; charset=utf-8"
  x = Builder::XmlMarkup.new(:indent=>2)
  x.instruct!
  x << '<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss"   xmlns:atom="http://www.w3.org/2005/Atom">'
  x.channel {
    x.title "UCLA Digital Collections Cooliris RSS feed"
    x.language "en-US"
    @results.each { |pic|
      x.item {
        url = params['redirect'] ? '/img/' + CGI::escape(pic[:thumb]) : pic[:thumb]
        fullres_url = params['redirect'] ? '/img/' + CGI::escape(pic[:fullres_url]) : pic[:fullres_url]
        x.title pic[:title]
        x.link pic[:url]
        x.media :thumbnail, {"url"=> url, "type" => "image/gif"}
        x.media :content, {"url"=>fullres_url, "type" => "image/jpeg"}
      }
    }
  }
  x << '</rss>'

end

get '/' do
  @query = params["q"]
  @sources = params["s"]

  return haml(:search) if @query.nil? or @query.empty? or @sources.nil? or @sources.empty?

  redirect "/#{@sources.join('+')}/#{ @query}"
end

get %r{/img/(.+)} do |url|
   redirect CGI::unescape url
end

get '/:sources/:query' do
  @query = params["query"]
  @sources = params["sources"].split(' ')
  @results = search @query, @sources

  return haml(:noresults) if @results.empty?

  @nresults = @results.size
  @nbslices = nbslices(@nresults,20)
  @details_store = "" # This string will contain the javascript code for the image's metadata.

  @rss_url = "/rss/#{@sources.join('+')}/#{CGI::escape @query}?redirect=yes"

  return haml(:view_panel)
end