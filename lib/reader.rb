# Inspired by http://gist.github.com/148238
# Build an inverted index for a full-text search engine with Redis.

require 'digest/md5'
require "iconv"

STOP_WORDS = %w(I a about an are as at be by com de en for from how  in is it la of on or that the this to was what when where  who will with und the www)

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
      content.tokenize_for_indexing.each { |word|
        @@db.sadd("wordindex:#{Digest::MD5.hexdigest(word)}",image_id)
      }
  end

  def self.remove_index
    @@db.delete_keys "wordindex:*"
    puts "Deleted old index"
  end

  def self.make_index
    remove_index
    collections = @@db.lrange "global:collections", 0, -1
    puts("There are no collections in the database") and return false if collections.empty?
    collections.each do |collection_id|
      collection = @@db.get "collections:#{collection_id}:name"
      images = @@db.lrange "collections:#{collection_id}:images", 0, -1
      puts "Indexing #{images.size} images for #{collection}"
      images.each do |image_id|
        image_path = "images:#{image_id}"
        image_title = @@db.get("#{image_path}:basic_info").split("|")[1]
        document = image_title + " " + @@db.get("#{image_path}:more_info") + " " + @@db.get("#{image_path}:keywords")
        index_image image_id, document.downcase
      end
    end
  end

  def self.search(query,collections=nil)
    if collections
      collections = collections.to_a
      c_ids = @@db.mget(collections.map { |name| "collections:#{name}:id" })
    else
      c_ids = @@db.lrange "global:collections", 0, -1
      collections = @@db.mget(c_ids.map { |id| "collections:#{id}:name" })
    end
    results = {}
    sets = query.tokenize_for_indexing.map{ |word|
      "wordindex:#{Digest::MD5.hexdigest(word)}"
    }
    files = @@db.sinter(*sets)

    collections.zip(c_ids).each do |collection, id|
      c_set = files & @@db.lrange("collections:#{id}:images", 0, -1)
      results.merge!({collection => nil}) and break if c_set.empty?
      c_set_data = @@db.mget(c_set.map { |id| "images:#{id}:basic_info" })
      results.merge!({collection => c_set_data.compact})
    end
    return results
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
  def tokenize_for_indexing
    self.strip.downcase.to_ascii_ugly.tr("^a-z0-9"," ").tr_s(" "," ").split(" ").uniq.delete_if { |word| (word.length < 3) or (STOP_WORDS.include? word) }
  end

  # Converts accentuated characters to a combination of their ASCII equivalent and the accent.
  # e.g. "à".to_ascii_ugly => "`a"
  def to_ascii_ugly
    Iconv.iconv("ascii//IGNORE//TRANSLIT", "utf-8", self)[0]
  end
end