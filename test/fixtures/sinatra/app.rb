require 'sinatra/base'

class SinatraApp < Sinatra::Base
  
  configure do
    set :root, File.expand_path(File.dirname(__FILE__))
  end
  
end