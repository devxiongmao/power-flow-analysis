ENV['APP_ENV'] = 'test'

require_relative '../app'
require 'rspec'
require 'rack/test'

RSpec.describe 'The HelloWorld App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /' do
    it 'renders the index page' do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Database Input Entry')
    end
  end

  describe 'GET /manual' do
    it 'renders the manual page' do
      get '/manual'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Manual Data Entry')
    end
  end

  describe 'GET /info' do
    it 'renders the info page' do
      get '/info'
      expect(last_response).to be_ok
      expect(last_response.body).to include('User Guide v1.0')
    end
  end

  describe 'GET /about' do
    it 'renders the about page' do
      get '/about'
      expect(last_response).to be_ok
      expect(last_response.body).to include('About the Developer Team')
    end
  end

  describe 'GET /download/bus' do
    it 'downloads bus_example.csv' do
      get '/download/bus'
      expect(last_response).to be_ok
      expect(last_response.headers['Content-Disposition']).to include('bus_example.csv')
    end
  end

  describe 'GET /download/line' do
    it 'downloads line_example.csv' do
      get '/download/line'
      expect(last_response).to be_ok
      expect(last_response.headers['Content-Disposition']).to include('line_example.csv')
    end
  end

  describe 'GET /download/:time' do
    let(:time) { '20240211' }
    let(:file_path) { "results/PowerFlowAnalysis-NR-#{time}.csv" }

    before do
      FileUtils.mkdir_p('results')
      File.open(file_path, 'w') { |file| file.write("column1,column2\nvalue1,value2") }
    end

    it 'downloads a time-stamped power flow analysis CSV' do
      get "/download/#{time}"
      expect(last_response).to be_ok
      expect(last_response.headers['Content-Disposition']).to include("PowerFlowAnalysis-NR-#{time}.csv")
    end

    after do
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  describe 'POST /check' do
    let(:bus_file) do
      Rack::Test::UploadedFile.new('spec/fixtures/bus_example.csv', 'text/csv')
    end

    let(:line_file) do
      Rack::Test::UploadedFile.new('spec/fixtures/line_example.csv', 'text/csv')
    end

    before do
      File.write('spec/fixtures/bus_example.csv', "Bus,Voltage,Angle\n1,1.0,0.0\n2,1.02,5.0")
      File.write('spec/fixtures/line_example.csv', "From,To,Impedance\n1,2,0.01+0.02j")
    end

    it 'processes uploaded CSV files and responds with success' do
      post '/check', busFile: bus_file, lineFile: line_file

      expect(last_response).to be_ok
      expect(last_response.body).to include("1.0")
      expect(last_response.body).to include("Manual Data Entry")
    end
  end
end
