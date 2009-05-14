class Collections
  class Collection
    @@data = "The values contained in the collection"
    @@dumppath = File.join File.expand_path(File.dirname(__FILE__)), "data"
    class << self
      
      def name
        "Default collection"
      end
      
      def save
        # Dumps the data on disk
        open(File.join("data","dump#{name}"), "w") { |f| Marshal.dump(@@data, f) }
      end

      def data
        @@data
      end
      
      def info
        "Default information about the collection class"
      end
      
      def generate
        "Instructions to retrieve the collection in case of corruption. Writes to @@data."
      end
      
      def search(s)
        "Searches for string _s_ in @@data. Returns an array [n,r] where n is the number of results and r is an array of results."
      end
    end
  end
        
  class DPF99 < Collection
    require 'rubygems'
    require 'mechanize'
    @@data = nil
    class << self
      def name
        "dpf99"
      end
      
      def info
        <<-EOF
          American Physical Society, Division of Particles and Fields
          Proceedings of the Los Angeles meeting held January 5-9, 1999
          
          Sample structure of the final hash
      
          [ 
            [
              "Session 1",
              [
                {:num => 0, :title => "a title", :speaker => "a name", ...},
                {:num => 1, :title => "another title", :speaker => "mr x", ...},
                ...
              ]
            ]
            [
              "Session 2",
              [
                {...},
                ...
              ]
            ]
          ]
        EOF
      end
      
      def generate
        dumpfile = File.join(@@dumppath,"dump#{name}")
        if File.exists? dumpfile
          @@data = File.open(dumpfile) { |f| Marshal.load(f) }
          return
        end
      
        url = "http://www.dpf99.library.ucla.edu"
      
        # Different ways of accessing each paper.
        # Add .<format> after the paper's link.
        link_formats = { "abstract" => "html",
                          "Latex" => "tex",
                          "PS" => "ps",
                          "PDF" => "pdf"
                        }
      
        #Removes non-printable characters, duplicate, leading and trialing whitespace
        def clean(s)
          s.gsub(/[^[:print:]]/, '').strip.gsub(/\s+/, ' ')
        end
      
        agent = WWW::Mechanize.new
        page = agent.get "#{url}/browsedpf99.html"
      
        proceedings = []
      
        page.root.css("html>body>center>table").each_with_index do |table,i|
  
          table.at("tr").remove #First <tr> is table header. We don't want that.
  
          proceedings << ["Session #{i+1}",[]]
  
          table.css("tr").each do |tr|
            fields = tr.css("td") #Fields are 0:number, 1:title, 2:speaker and 3:link
            
            num = clean(fields[0].text)
            title = clean(fields[1].text)
            speaker = clean(fields[2].text)
            
            if fields[3].at("a").nil?
              link, abstract = nil
            else
              link = url + fields[3].at("a")["href"].gsub(/\.(.*)\.html/,'\1') 
              page = agent.get("#{link}.#{link_formats["abstract"]}")
              abstract = page.root.css("html>body>p:nth-of-type(4)").text
            end
            
            blob = "#{title} #{speaker} #{abstract}"
    
            proceedings[i][1] << { :num => num,
                                :title => title,
                                :speaker => speaker,
                                :link => link,
                                :abstract => abstract,
                                :blob => blob
                              }
          end
        end
        File.open(dumpfile,"w") { |f| Marshal.dump(proceedings,f) }
        @@data = proceedings
      end
      
      def search(s)
        results = []
        n = 0
        @@data.each do |session|
          session[1].each do |paper|
            if paper[:blob] =~ /#{s}/i
              n = n+1
              results << [session[0], paper]
            end
          end
        end
        return [n, results]
      end
    end
  end
end