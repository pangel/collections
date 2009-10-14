require 'pp'

%w(loader reader redisdb app_env).each { |file|
  require File.join(File.expand_path(File.dirname(__FILE__)), "lib", file)
}

begin
  Reader.database(RedisDB.connect)
  Loader.database(RedisDB.connect)
rescue
  # If the redis server is not started yet, there will be an error.
end

namespace :app do
  task :deploy do
    Dir.chdir '/var/www/vcs/collections/'
    puts `git pull`
    puts `git checkout-index -a -f --prefix=/var/www/collections.pangel.fr/`
    Dir.chdir '/var/www/collections.pangel.fr'
    puts `/etc/init.d/thin restart`
    puts "Deploy complete"
  end
end

namespace :db do
  desc "Starts the redis server"
  task :start do
    conf_file = File.join(File.expand_path(File.dirname(__FILE__)),"redis.conf")
    resp = `redis-server #{conf_file}`
    if resp.empty?
      RedisDB.connect.set "db:name", APP_NAME
      puts "Redis server started on port #{REDIS_PORT}."
    else
      puts "Redis server responded:\n#{resp}"
    end
  end

  desc "Stop the redis server"
  task :stop do
    puts "NOT IMPLEMENTED"
    #a=RedisDB.connect
    # a.shutdown
    # TODO: callshutdown, rescue errconnect (means the server IS down) and say "all good". If no errconnect, then the server is not down.
    #  `kill #{File.open('/var/run/redis.pid').read.chomp}`

    #   def shutdown
    #     begin
    #       info
    #       process_command("shutdown\r\n", [["shutdown"]])
    #     rescue Errno::ECONNRESET
    #       return 1
    #     end
    #   end
    # end
  end

  desc "Drops all the database content"
  task :drop do
    puts "Redis database is now empty." if RedisDB.connect.flushall
  end

  desc "Loads the database with all the available collections"
  task :load do
    puts "Loaded all collections" if Loader.write_collections
  end

  task :console do
    require 'irb'
    module IRB # :nodoc:
      def self.start_session(binding)
        unless @__initialized
          args = ARGV
          ARGV.replace(ARGV.dup)
          IRB.setup(nil)
          ARGV.replace(args)
          @__initialized = true
        end

        workspace = WorkSpace.new(binding)

        irb = Irb.new(workspace)

        @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
        @CONF[:MAIN_CONTEXT] = irb.context

        catch(:IRB_EXIT) do
          irb.eval_input
        end
      end
    end

    db = RedisDB.connect

    puts "You are now in irb. Database object is db"
    IRB.start_session(binding)
  end

  desc "Restarts the database."
  task :restart do
    Rake::Task["db:stop"].execute
    Rake::Task["db:start"].execute
  end

  desc "Writes DB to disk."
  task :save do
    RedisDB.connect.save
  end

  desc "Rebuilds the index from scratch"
  task :index do
    puts "All images' metadata successfully indexed" if Reader.make_index
  end

  desc "Runs a full text search using the given query"
  task :search, :query, :source do |t,args|
    source = args[:source] || "latimes"
    pp Reader.search(args[:query], source)
  end
end