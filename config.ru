require 'application'

set :run, false
set :environment, (ENV['DATABASE_URL'] ? :production : :development)
set :haml, {:format => :html4, :ugly => true} # Ugly HTML, faster rendering
set :clean_trace, false
run Sinatra::Application