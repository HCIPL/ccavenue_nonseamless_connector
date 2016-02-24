require 'sinatra/base'
require 'rack/contrib'
require 'sinatra/config_file'
require 'active_record'
require 'securerandom'
require 'haml'
require 'json'
require 'pry'

require_relative 'crypto'

class CCAvenueNonSeamless < Sinatra::Application
  register Sinatra::ConfigFile
  use Rack::PostBodyContentTypeParser

  config_file './settings.yml'
  $settings = settings

  get '/' do
    erb :index
  end

  post '/transaction/ccavRequestHandler' do
    erb :ccavRequestHandler
  end

  post '/transaction/ccavResponseHandler' do
    erb :ccavResponseHandler
  end

  post '/api/v1/patients/:patient_id/payments' do
    id = Time.now
    request.params.merge!(patient_id: params[:patient_id], id: id.to_i)
    File.open('payments/'+id.to_s+'_create'+'.txt', 'w') { |file| file.write(request.params.to_json) }
    headers['REDIRECT_URL'] = "#{$settings.base_url}/api/v1/payments/#{id.to_i}/initiate"
    status 201
    request.params.to_json
  end

  get '/api/v1/payments/:id' do
    payment_id = params[:id].to_i
    file = File.read('payments/'+Time.at(payment_id).to_s+'_create'+'.txt')
    halt 404 unless file
    payment = JSON.parse(file)
    status 200
    payment.to_json
  end

  get '/api/v1/payments/:payment_id/initiate' do
    payment_id = params[:payment_id].to_i
    file = File.read('payments/'+Time.at(payment_id).to_s+'_create'+'.txt')
    halt 404 unless file
    payment = JSON.parse(file)

    hash = {
      merchant_id: $settings.ccavenue[:merchant_id],
      order_id: payment_id,
      amount: "%.2f" % payment['amount'],
      currency: payment[:currency],
      language: 'EN',
      redirect_url: "#{settings.base_url}/api/v1/payments/#{payment_id}/completions",
      cancel_url: "#{settings.base_url}/api/v1/payments/#{payment_id}/cancellations"
    }

    merchantData = ""
    hash.each do |key, value|
      merchantData += "#{key}"+"="+"#{value}"+"&"
    end

    @encrypted_data = Crypto.new.encrypt(merchantData, $settings.ccavenue[:working_key])

    haml :payment_initiate
  end

  post '/api/v1/payments/:payment_id/completions' do
    payment_id = Time.at(params[:payment_id].to_i)
    File.open('completions/'+payment_id.to_s+'_complete'+'.txt', 'w') { |file| file.write(request.params.to_json) }
    # headers['REDIRECT_URL'] = "#{$settings.base_url}/api/v1/payments/#{id.to_i}/initiate"
    # status 201
    # json request.params
    haml :payment_end
  end

  post '/api/v1/payments/:payment_id/cancellation' do
    payment_id = Time.at(params[:payment_id].to_i)
    File.open('cancellations/'+payment_id.to_s+'_cancel'+'.txt', 'w') { |file| file.write(request.params.to_json) }
    haml :payment_end
  end

  post '/transaction/ccavCancelHandler' do
    redirect '/'
  end
end
