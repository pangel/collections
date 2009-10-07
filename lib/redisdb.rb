require 'rubygems'
gem 'redis', '~> 0.2.0'
require 'redis'

require File.join(File.expand_path(File.dirname(__FILE__)), "app_env")

class RedisDB < Redis
  def self.connect
    this = self.new :host => REDIS_HOST, :port => REDIS_PORT
    # Gets out if the database is neither APP_NAME nor blank.
    raise ScriptError::LoadError, "This database belongs to another application. DB name: #{this.get("db:name")}" unless [APP_NAME, nil].include? this.get("db:name")
    this
  end

  def delete_keys(*patterns)
    patterns.each { |pattern|
      self.keys(pattern).map { |key|
        response = self.del(key)
        p "#{key} did not exist" unless response
      }
    }
  end
end