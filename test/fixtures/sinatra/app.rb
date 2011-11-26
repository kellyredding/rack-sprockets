require 'sinatra/base'

class SinatraApp < Sinatra::Base

  configure do
    set :root, File.expand_path(File.dirname(__FILE__))
  end

  use Rack::Sprockets,
    :root => root,
    :load_path => ["app/javascripts"]

  get '/app.js' do
    "not the response you are looking for"
  end

end
