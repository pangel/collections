require 'open-uri'
require 'dpf99'
require 'pathname'
require 'rubygems'
require 'mechanize'

PDF = "/images/pdf.png"

class CollectionReader
  @@agent = WWW::Mechanize.new
  
    #Removes non-printable characters, duplicate, leading and trialing whitespace
  def self.clean(s)
    s.gsub(/[^[:print:]]/, '').strip.gsub(/\s+/, ' ')
  end

# This is the interface from the collections to the searchers
# Results must be hashes with this structure
# :url, :thumb, :full, :title, :collection, :collection_url  
  @@collections = {
    "aids" => Proc.new { |query|
      agent = @@agent
      collection = "AIDS Posters"
      collection_url = 'http://digital.library.ucla.edu/aidsposters/librarian?SEARCHPAGE&Search'
      page = agent.get(collection_url)
      form = page.form('sForm')
      form.KEYWORD = query
      form.add_field!("NUMDISPLAYED", "72")
      page = agent.submit(form).root
      page.css('table.OutlineFaint').inject([]) do |acc,table|
        url = table.search('a').first['href']
        page = agent.get(url).root
        title = clean(page.at("td.LabelBold").text)
        thumb_img = table.search('img').first['src']
        img_a = page.css('td.OutlineFaint td.outline a')[1]
        if img_a.nil? # Some image do not have a full-res version
          full_img = thumb_img
        else
          img_url =page.css('td.OutlineFaint td.outline a')[1]['href'].match(/StartItemWin\('(.*)',/)[1] 
          full_img = agent.get(img_url).root.css('img').first['src']
        end
        acc << {:url => url, :thumb => thumb_img, :full => full_img, :title => title, :collection => collection, :collection_url => collection_url}
        end
    },
    "dpf99" => Proc.new { |query|
      agent = @@agent
      collection = "American Physical Society, Division of Particles and Fields: Proceedings of the Los Angeles meeting held January 5-9, 1999"
      collection_url = "http://www.dpf99.library.ucla.edu/"
      Collections::DPF99.generate
      Collections::DPF99.search(query)[1].map { |r| {:url => "#{r[1][:link]}.html", :thumb => PDF, :full => "#{r[1][:link]}.pdf", :title => r[1][:title], :collection => collection, :collection_url => collection_url }
      }
    },
    "latimes" => Proc.new { |query|
      collection = "Changing Times: Los Angeles in Photographs, 1920-1990"
      collection_url = "http://unitproj.library.ucla.edu/dlib/lat/"
      req = "http://unitproj.library.ucla.edu/dlib/lat/search.cfm?k=#{query}&w=none&x=title&y=none&z=none&all"
      doc = Nokogiri::HTML open(req)
      elements = []
      (doc/'a[@href^="display.cfm"]').each do |el|
        elements << el if (not el.at("img").nil?)
      end
      elements.map! do |el|
        url = collection_url + el[:href]
        thumb = el.at("img")[:src]
        full = el.at("img")[:src].sub(/i\.gif/, "j.jpg")
        title = el.next_sibling.next_sibling.inner_text
        {:thumb => thumb, :full => full, :title => title, :url => url, :collection => collection, :collection_url => collection_url}
      end
    },
    "pmtcards" => Proc.new { |query|
      collection = "Patent Medicine Trade Cards"
      collection_url ="http://unitproj.library.ucla.edu/dlib/medicinecards/"
      req = "http://unitproj.library.ucla.edu/dlib/medicinecards/search.cfm?k=#{query}&all"
      doc = Nokogiri::HTML open(req)
      elements = (doc/'a[@href^="display.cfm"]').inject([]) do |acc,el|
          acc << el if (not el.at("img").nil?)
        end
        elements.map! do |el|
          url = collection_url + el[:href]
          thumb = el.at("img")[:src]
          full = el.at("img")[:src].sub(/i\.gif/, "j.jpg")
          title = el.parent.parent.next_sibling.inner_text
          {:thumb => thumb, :full => full, :title => title, :url => url, :collection => collection, :collection_url => collection_url}
        end
    }
  }
  def self.fetch(query, *sources)
   results = Hash.new { |hash, key| hash[key] = @@collections[key].call(query) }
   results.values_at *sources
   return results
  end
  
  def self.xml(collections)
    require 'builder'
    markup = ""
    xml_markup = Builder::XmlMarkup.new :indent => 2, :target => markup
    xml_markup.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    xml_markup.results do |results|
      collections.each do |collection_name,records|
        results.collection("name"=>collection_name) do |c|
          records.each do |record|
            c.record do |r|
              r.collectionname record[:collection]
              r.collectionurl record[:collection_url]
              r.url record[:url]
              r.thumb record[:thumb]
              r.title record[:title]
              r.full record[:full]
            end
          end
        end
      end
    end
    markup
  end
end

if $0 == __FILE__
  pp CollectionReader.fetch("pol","aids")
end