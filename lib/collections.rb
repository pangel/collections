require "open-uri"
require "rubygems"
require "parallel"
require "nokogiri"

Collection = Struct.new :name,
                        :url,
                        :description,
                        :images

class Collection

  @@collections = []
  def self.collections
    @@collections
  end

  def initialize(*args)
    @@collections << self
    super(args)
  end

  # This method expects that the Collection instance has
  # - the records_list method. Outputs a collection of elements which get_record must understand.
  # - the get_record method. Takes an element of records_list's output as input. Outputs an instance of CollectionImage.
  def collect_records(links=records_list)
    images = []
    links = links
    loop do
      failed_links = []
      # Parallel request of all the images across 50 processes
      images_slice = Parallel.map(links, :in_threads => 50) do |link|
        begin
          get_record(link)
        rescue Errno::ETIMEDOUT, Timeout::Error => e
          failed_links << link
          puts "Failed #{failed_links.size} elements."
          next
        end
      end
      images.push images_slice
      break if failed_links.empty?
      links = failed_links
    end
    return images.flatten.compact
  end

  def to_s
    self.name
  end
  alias :images :collect_records
end

Dir.glob(File.join(File.dirname(File.expand_path(__FILE__)), "collections") + File::SEPARATOR + "*.rb").each { |collection| require collection }

CollectionImage = Struct.new :thumb_url,
                             :fullres_url,
                             :title,
                             :description,
                             :url,
                             :date,
                             :source,
                             :keywords
