class Array
  def each_slice_with_index(slice_size)
    self.enum_slice(slice_size).each_with_index { |slice,index|
      yield slice,index
    }
  end
end

module Helpers
  # From http://rails.rubyonrails.org/classes/ActionView/Helpers/JavaScriptHelper.html#M000440
  JS_ESCAPE_MAP = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }

  def escape_javascript(javascript)
    if javascript
      javascript.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { JS_ESCAPE_MAP[$1] }
    else
     ''
    end
  end

  def partial(name, options={})
    haml "_#{name}".to_sym, options.merge(:layout => false)
  end

  def normalize(results)
    results.reject { |d|
      d["submasterFileId"].nil?
    }.map { |e|
      collection = COLLECTIONS[e["projectId"]]
      {
        :title          => hj(e["title"]),
        :collection     => hj(collection["name"]),
        :collection_url => hj(collection["url"]),
        :url            => hj("http://digital2.library.ucla.edu/viewItem.do?ark=" + e["ark"]),
        :fullres_url    => hj("http://digital2.library.ucla.edu/imageResize.do?scaleFactor=1&contentFileId=" + e["submasterFileId"]),
        :thumb          => hj(e["thumbnailURL"])
      }
    }
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
    begin
      response = HTTParty.get "http://digital2.library.ucla.edu/testAjax.do", :query => params.join('&'), :format => :json
    rescue Crack::ParseError
      return []
    end
    normalize response
  end

  # Returns the ceiling of the division of q by d
  # Using float is not precise enough
  def nbslices(q,d)
    divmod = q.divmod(d)
    divmod[0] + (divmod[1] > 0 ? 1 : 0)
  end
end