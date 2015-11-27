require 'sinatra/base'
require 'sinatra/config_file'
require 'active_record'
require 'rack/csrf'
require 'securerandom'

require_relative 'crypto'

class CCAvenueNonSeamless < Sinatra::Application
  register Sinatra::ConfigFile
  use Rack::Csrf, :raise => true, skip: ['POST:/transaction/ccavRequestHandler']

  config_file './settings.yml'
  set :sessions, true
  # set :session_secret, 'Secret Kye'


  get '/' do
    session[:key] = SecureRandom.hex
    erb :index
  end

  post '/transaction/ccavRequestHandler' do
    erb :ccavRequestHandler
  end

  post '/transaction/ccavResponseHandler' do
    erb :ccavResponseHandler
  end

  post '/transaction/ccavCancelHandler' do
    redirect '/'
  end
end
