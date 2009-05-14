require 'dpf99'
require 'pathname'
require 'rubygems'
require 'mechanize'

PDF = "* a pdf file *"

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
        img_url =page.css('td.OutlineFaint td.outline a')[1]['href'].match(/StartItemWin\('(.*)',/)[1] 
        full_img = agent.get(img_url).root.css('img').first['src']
        thumb_img = table.search('img').first['src']
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
    collections.each do |collection,records|
      xml_markup.collection do |c|
        records.each do |result|
          xml_markup.record do |r|
            r.collectionname result[:collection]
            r.collectionurl result[:collection_url]
            r.url result[:url]
            r.thumb result[:thumb]
            r.title result[:title]
            r.full result[:full]
          end
        end
      end
    end
    markup
  end
end

if $0 == __FILE__
  pp CollectionReader.fetch("high","aids")
end