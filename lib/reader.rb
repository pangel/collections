# Inspired by http://gist.github.com/148238
# Build an inverted index for a full-text search engine with Redis.

require 'digest/md5'
require "iconv"

STOP_WORDS = %w(I a about an are as at be by com de en for from how in is it la of on or that the this to was what when where who will with und the www)

class Reader
  def self.database(db)
    @@db = db
    return self
  end

  # def self.get_file_id(filename)
    #     md5 = Digest::MD5.hexdigest(filename)
    #     id = @@db.get("file:#{md5}:id")
    #     if not id
    #       id = @@db.incr("file:next.id")
    #       @@db.set("file:#{md5}:id", id)
    #       @@db.set("file:#{id}:string",filename)
    #     end
    #     return id.to_i
    # end

  def self.index_image image_id, content
      content.tokenize.each { |word|
        @@db.sadd("wordindex:#{Digest::MD5.hexdigest(word)}",image_id)
      }
  end

  def self.remove_index
    @@db.delete_keys "wordindex:*"
    puts "Deleted old index"
  end

  def self.make_index
    remove_index
    collections = @@db.smembers "global:collections"
    puts("There are no collections in the database") and return false if collections.empty?
    collections.each do |collection_id|
      collection = @@db.get "collections:#{collection_id}:name"
      images = @@db.smembers "collections:#{collection_id}:images"
      puts "Indexing #{images.size} images for #{collection}"
      images.each do |image_id|
        image_path = "images:#{image_id}"
        image_title = @@db.get("#{image_path}:basic_info").split("|")[1]
        document = image_title + " " + @@db.get("#{image_path}:more_info") + " " + @@db.get("#{image_path}:keywords")
        index_image image_id, document.downcase
      end
    end
  end

  def self.search(query,collection)
    raise "No such collection: #{collection}" unless @@db.get "collections:#{collection}:id"
    id = @@db.get "collections:#{collection}:id"
    sets = query.tokenize.map { |word|
      "wordindex:#{Digest::MD5.hexdigest(word)}"
    }
    images = @@db.sinter("collections:#{id}:images", *sets).map { |id|
      "images:#{id}:basic_info"
    }
    return images if images.empty?
    return @@db.mget *images
  end
end

class String
  # 1. Converts to lowercase
  # 2. Converts accentuated characters to their ASCII equivalent+the accent
  # 3. Removes all non-text and non-digit characters
  # 4. Squeezes multi-spaces ("  ") into one (" ")
  # 5. Converts to array, splits between spaces (" ")
  # 6. Removes duplicates
  # 7. Removes words of less than 3 letters and members of STOP_WORDS
  def tokenize
    self.strip.downcase.to_ascii_ugly.tr("^a-z0-9"," ").tr_s(" "," ").split(" ").uniq.delete_if { |word| (word.length < 3) or (STOP_WORDS.include? word) }
  end

  # Converts accentuated characters to a combination of their ASCII equivalent and the accent.
  # e.g. "à".to_ascii_ugly => "`a"
  def to_ascii_ugly
    Iconv.iconv("ascii//IGNORE//TRANSLIT", "utf-8", self)[0]
  end
end