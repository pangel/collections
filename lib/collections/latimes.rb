# Initialize the latimes Collection
latimes = Collection.new

latimes.name = "latimes"

latimes.url = "http://unitproj.library.ucla.edu/dlib/lat/introduction.cfm"

latimes.description = "Featuring more than five thousand of the three million images contained in the Los Angeles Times and Los Angeles Daily News photographic archives   housed in the Charles E. Young Research Library Department of Special Collections, this collection chronicles the history and growth of Los Angeles from the 1920s to   1990."

def latimes.records_list
  # Get the list of all the records
  dumpfile = File.join(File.expand_path(File.dirname(__FILE__)),"dump_latimes_page")

  if File.exists? dumpfile
    @page = File.open(dumpfile) { |f| Marshal.load(f) }
    puts "Latimes: Retrieved index page from file."
  else
    @page = open("http://unitproj.library.ucla.edu/dlib/lat/search.cfm?k=%20&w=none&x=title&y=none&z=none&all") { |f| f.read }
    File.open(dumpfile,"w") { |f| Marshal.dump(@page,f) }
    puts "Latimes: Retrieved index page from web."
  end

  # Extract the links to the images from the index page.
  Nokogiri::HTML.parse(@page).search('a[@href^="display.cfm"][1]')
end

# Follows the record's (_el_) link and gets its details from there.
def latimes.get_record(el)
  image = CollectionImage.new

  image.url = "http://unitproj.library.ucla.edu/dlib/lat/" + el[:href]
  image.thumb_url = el.at("img")[:src]
  image.fullres_url = el.at("img")[:src].sub(/i\.gif/, "j.jpg")
  details_page = ""

  details_page = Nokogiri::HTML.parse(open(image.url))

  image.title = details_page.at('/html/body/div[2]/table/tr[3]/td/table/tr[2]/td/table/tr/td/table/tr/td[2]/i/strong').content
  image.description = details_page.at('/html/body/div[2]/table/tr[3]/td/table/tr[2]/td/table/tr/td/table/tr[2]/td[2]').content
  image.source = details_page.at('/html/body/div[2]/table/tr[3]/td/table/tr[2]/td/table/tr/td/table/tr[3]/td[2]').content
  image.date = details_page.at('/html/body/div[2]/table/tr[3]/td/table/tr[2]/td/table/tr/td/table/tr[4]/td[2]').content

  image.keywords = ""
  keywords = details_page.at('/html/body/div[2]/table/tr[3]/td/table/tr[2]/td/table/tr/td/table/tr[5]/td[2]')

  # If the image has notes in addition to its tags, add them and move to the tags.
  if keywords.at("a").nil?
    image.keywords = keywords.content + " "
    keywords = keywords.parent.next_sibling.at('td[2]')
  end

  image.keywords << keywords.search("a").map {|a| a.content }.to_a.join(" ")

  # Remove undesired newline and other escape characters.
  image.keywords.gsub! /\r|\t|\n/, ""

  # Add the new image record to the list of images.
  return image
end
