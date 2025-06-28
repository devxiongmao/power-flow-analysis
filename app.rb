# frozen_string_literal: true

require 'sinatra'
require_relative 'lib/power_flow_service'
require 'csv'
require 'webrick'
require 'webrick/https'
require 'openssl'

set :bind, '0.0.0.0'
set :protection, except: :host
set :allowed_hosts, [ 'power-flow-analysis.fly.dev' ]

# cert = OpenSSL::X509::Certificate.new File.read 'c:/Apache24/htdocs/server.crt'
# pkey = OpenSSL::PKey::RSA.new File.read 'c:/Apache24/htdocs/server.key'

# server = WEBrick::HTTPServer.new(:Port => 4567,
#                                 :SSLEnable => true,
#                                 :SSLCertificate => cert,
#                                 :SSLPrivateKey => pkey)

# Initialize the power flow service
power_flow_service = PowerFlowService.new

get('/') do
  erb :index
end

get('/manual') do
  erb :manual
end

get('/info') do
  erb :info
end

get('/about') do
  erb :about
end

get('/download/bus') do
  send_file 'bus_example.csv', filename: 'bus_example.csv'
end

get('/download/line') do
  send_file 'line_example.csv', filename: 'line_example.csv'
end

get('/download/:time') do
  time = params['time'].to_s
  send_file "results/PowerFlowAnalysis-NR-#{time}.csv", filename: "PowerFlowAnalysis-NR-#{time}.csv"
end

post('/check') do
  processed_data = power_flow_service.process_csv_files(params[:busFile], params[:lineFile])

  @bus_data = processed_data[:bus_data]
  @line_data = processed_data[:line_data]
  @all_bus_lines = params[:busFile][:tempfile].read.split("\r\n")
  @all_line_lines = params[:lineFile][:tempfile].read.split("\r\n")

  erb :post_check
end

post('/analyze') do
  # Perform power flow analysis using the service
  analysis_result = power_flow_service.analyze_power_flow(params)

  # Extract results for the view
  results = analysis_result[:results]
  @time = analysis_result[:time]

  # Set instance variables for the view
  @num_of_buses = results[:num_of_buses]
  @types = results[:types]
  @v_data = results[:v_data]
  @d_data = results[:d_data]
  @p_data = results[:p_data]
  @q_data = results[:q_data]
  @del_degree = results[:del_degree]
  @z = results[:z]
  @p_injection = results[:p_injection]
  @q_injection = results[:q_injection]
  @power_generated = results[:power_generated]
  @reactive_generated = results[:reactive_generated]
  @pTotal = results[:totals][:pTotal]
  @qTotal = results[:totals][:qTotal]
  @pgTotal = results[:totals][:pgTotal]
  @qgTotal = results[:totals][:qgTotal]
  @plTotal = results[:totals][:plTotal]
  @qlTotal = results[:totals][:qlTotal]
  @line_loss_1 = results[:line_loss_1]
  @line_loss_2 = results[:line_loss_2]

  # Add the original data for the view
  @pl_data = results[:pl_data]
  @ql_data = results[:ql_data]

  erb :result

  # send_file "PowerFlowAnalysis-NR-#{time}.csv", :filename => "PowerFlowAnalysis-NR-#{time}.csv"
end
