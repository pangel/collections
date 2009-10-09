require File.join(File.expand_path(File.dirname(__FILE__)), "collections")

class Loader

  def self.database(db)
    @@db = db
    return self
  end

  def self.collections
    Collection.collections
  end

  def self.write_collections(sources=collections)
    sources.each { |collection|
      write_records(collection)
    }
  end

  private
  def self.write_records(collection)
    delete_collection(collection)
    collection_id = @@db.incr "global:next_collection_id"
    @@db.sadd "global:collections", collection_id
    @@db["collections:#{collection_id}:name"] = collection.name
    @@db["collections:#{collection_id}:url"] = collection.url
    @@db["collections:#{collection.name}:id"] = collection_id
    collection.images.each do |image|
      image_id = @@db.incr "global:next_image_id"
      image_path = "images:#{image_id}"
      @@db["#{image_path}:basic_info"] = "#{collection_id}|#{image.title}|#{image.thumb_url}|#{image.fullres_url}|#{image.url}"
      @@db["#{image_path}:more_info"] = "#{image.description}|#{image.date}|#{image.source}"
      @@db["#{image_path}:keywords"] = image.keywords
      @@db.sadd "collections:#{collection_id}:images", image_id
    end
  end

  def self.delete_collection(collection)
    collection_id = @@db.get("collections:#{collection.name}:id")
    @@db.del "collections:#{collection.name}:id"
    @@db.del "collections:#{collection_id}:name"
    @@db.del "global:collections", 1, collection_id
    images = @@db.lrange("collections:#{collection_id}:images", 0, -1)
    unless images.nil?
      images.each { |image_id|
        @@db.delete_keys("images:#{image_id}*")
      }
    end
    @@db.del "collections:#{collection_id}:images"
  end
end