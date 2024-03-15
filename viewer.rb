# This script start a local server to visualize files in this folder.

require 'sinatra' # gem install sinatra

set :public_folder, File.dirname(__FILE__)

get '/' do
  send_file 'index.html'
end
