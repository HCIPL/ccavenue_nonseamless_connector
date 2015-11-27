require 'sinatra/base'
require 'sinatra/config_file'
require 'active_record'
require 'securerandom'

require_relative 'crypto'

class CCAvenueNonSeamless < Sinatra::Application
  register Sinatra::ConfigFile

  config_file './settings.yml'

  get '/' do
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
