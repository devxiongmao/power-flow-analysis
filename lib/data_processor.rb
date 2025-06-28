# frozen_string_literal: true

# Handles parsing and processing of input data from CSV files and form parameters
class DataProcessor
  def initialize
    @bus_data = []
    @line_data = []
  end

  def process_csv_files(bus_file, line_file)
    @bus_data = parse_csv_file(bus_file)
    @line_data = parse_csv_file(line_file)
    
    {
      bus_data: @bus_data,
      line_data: @line_data
    }
  end

  def count_entities(params)
    num_of_buses = 0
    num_of_lines = 0

    params.each_key do |key|
      num_of_buses += 1 if key.include?('type')
      num_of_lines += 1 if key.include?('from')
    end

    {
      num_of_buses: num_of_buses,
      num_of_lines: num_of_lines
    }
  end

  private

  def parse_csv_file(file)
    content = file[:tempfile].read
    lines = content.split("\r\n")
    
    # Skip header row and parse data
    data = []
    lines.each_with_index do |line, i|
      next if i.zero?
      line.split(',').each { |value| data.push(value) }
    end
    
    data
  end
end 