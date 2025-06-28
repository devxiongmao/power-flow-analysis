# frozen_string_literal: true

require_relative "power_flow_analyzer"
require_relative "csv_generator"
require_relative "data_processor"

# Orchestrates the power flow analysis process
class PowerFlowService
  def initialize
    @data_processor = DataProcessor.new
  end

  def analyze_power_flow(params)
    # Count buses and lines from parameters
    counts = @data_processor.count_entities(params)

    # Prepare data for analysis
    bus_data = {
      num_of_buses: counts[:num_of_buses],
      params: params
    }

    line_data = {
      num_of_lines: counts[:num_of_lines]
    }

    # Perform power flow analysis
    analyzer = PowerFlowAnalyzer.new(bus_data, line_data)
    results = analyzer.analyze

    # Generate CSV file
    time = Time.now.strftime("%d-%m-%Y-%H-%M-%S")
    csv_generator = CsvGenerator.new(results, time)
    filename = csv_generator.generate_csv

    {
      results: results,
      filename: filename,
      time: time
    }
  end

  def process_csv_files(bus_file, line_file)
    @data_processor.process_csv_files(bus_file, line_file)
  end
end
