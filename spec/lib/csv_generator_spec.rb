# frozen_string_literal: true

require_relative '../../lib/csv_generator'
require 'csv'
require 'fileutils'

RSpec.describe CsvGenerator do
  let(:sample_results) do
    {
      num_of_buses: 3,
      types: [ 'Slack', 'PV', 'PQ' ],
      v_data: [ 1.05, 1.02, 0.98 ],
      d_data: [ 0.0, -2.5, -5.2 ],
      p_data: [ 2.5, 1.8, -1.2 ],
      q_data: [ 1.2, 0.8, -0.6 ],
      del_degree: [ 0.0, -2.5, -5.2 ],
      z: [
        [ 1, 2, 1.5, 0.8, nil, nil, -1.4, -0.7, 0.1, 0.1 ],
        [ 2, 3, 0.9, 0.4, nil, nil, -0.85, -0.35, 0.05, 0.05 ]
      ],
      p_injection: [ 2.5, 1.8, -1.2 ],
      q_injection: [ 1.2, 0.8, -0.6 ],
      power_generated: [ 2.7, 2.0, 0.0 ],
      reactive_generated: [ 1.4, 0.9, 0.0 ],
      pl_data: [ 0.2, 0.2, 1.2 ],
      ql_data: [ 0.2, 0.1, 0.6 ],
      totals: {
        pTotal: 3.1,
        qTotal: 1.4,
        pgTotal: 4.7,
        qgTotal: 2.3,
        plTotal: 1.6,
        qlTotal: 0.9
      },
      line_loss_1: 0.15,
      line_loss_2: 0.15
    }
  end

  let(:timestamp) { '20241201_143022' }
  subject(:generator) { described_class.new(sample_results, timestamp) }

  before do
    # Clean up any existing results directory before each test
    FileUtils.rm_rf('results') if Dir.exist?('results')
  end

  after do
    # Clean up results directory after each test
    FileUtils.rm_rf('results') if Dir.exist?('results')
  end

  describe '#initialize' do
    it 'assigns all result data to instance variables' do
      expect(generator.instance_variable_get(:@results)).to eq(sample_results)
      expect(generator.instance_variable_get(:@time)).to eq(timestamp)
      expect(generator.instance_variable_get(:@num_of_buses)).to eq(3)
      expect(generator.instance_variable_get(:@types)).to eq([ 'Slack', 'PV', 'PQ' ])
      expect(generator.instance_variable_get(:@v_data)).to eq([ 1.05, 1.02, 0.98 ])
      expect(generator.instance_variable_get(:@totals)).to eq(sample_results[:totals])
    end
  end

  describe '#generate_csv' do
    let(:expected_filename) { "results/PowerFlowAnalysis-NR-#{timestamp}.csv" }

    it 'creates the results directory if it does not exist' do
      expect(Dir.exist?('results')).to be false

      generator.generate_csv

      expect(Dir.exist?('results')).to be true
    end

    it 'returns the correct filename' do
      filename = generator.generate_csv
      expect(filename).to eq(expected_filename)
    end

    it 'creates a CSV file with the correct filename' do
      generator.generate_csv
      expect(File.exist?(expected_filename)).to be true
    end

    it 'generates CSV with correct bus summary section' do
      generator.generate_csv

      csv_content = CSV.read(expected_filename)

      # Check headers
      expect(csv_content[0]).to eq([ 'Bus Number', 'Type', 'V', 'D', 'P', 'Q' ])

      # Check first bus data
      expect(csv_content[1]).to eq([ '1', 'Slack', '1.05', '0.0', '2.5', '1.2' ])
      expect(csv_content[2]).to eq([ '2', 'PV', '1.02', '-2.5', '1.8', '0.8' ])
      expect(csv_content[3]).to eq([ '3', 'PQ', '0.98', '-5.2', '-1.2', '-0.6' ])
    end

    it 'generates CSV with correct detailed analysis section' do
      generator.generate_csv

      csv_content = CSV.read(expected_filename)

      # Find the detailed analysis header
      header_row = csv_content.find_index { |row| row[0] == 'Newton Raphson Load Flow Analysis' }
      expect(header_row).not_to be_nil

      # Check column headers
      column_headers = csv_content[header_row + 1]
      expected_headers = [ 'Bus #', 'V (pu)', 'Angle (degree)', 'Injection MW', 'Injection MVar',
                         'Generation MW', 'Generation MVar', 'Load MW', 'Load MVar' ]
      expect(column_headers).to eq(expected_headers)

      # Check first bus detailed data
      bus1_data = csv_content[header_row + 2]
      expect(bus1_data).to eq([ '1', '1.05', '0.0', '2.5', '1.2', '2.7', '1.4', '0.2', '0.2' ])

      # Check totals row
      totals_row = csv_content[header_row + 5]  # After 3 bus rows
      expect(totals_row[0]).to eq('Total')
      expect(totals_row[3]).to eq('3.1')  # pTotal
      expect(totals_row[4]).to eq('1.4')  # qTotal
    end

    it 'generates CSV with correct line flows section' do
      generator.generate_csv

      csv_content = CSV.read(expected_filename)

      # Find the line flows header
      header_row = csv_content.find_index { |row| row[0] == 'Line Flows and Losses' }
      expect(header_row).not_to be_nil

      # Check column headers
      column_headers = csv_content[header_row + 1]
      expected_headers = [ 'From Bus', 'To Bus', 'P MW', 'Q MVar', 'From Bus', 'To Bus',
                         'P MW', 'Q MVar', 'Line Loss MW', 'Line Loss MVar' ]
      expect(column_headers).to eq(expected_headers)

      # Check first line flow data
      line1_data = csv_content[header_row + 2]
      expect(line1_data).to eq([ '1', '2', '1.5', '0.8', '2', '1', '-1.4', '-0.7', '0.1', '0.1' ])

      # Check line losses total
      total_loss_row = csv_content[header_row + 4]  # After 2 line flow rows
      expect(total_loss_row[0]).to eq('Total Loss')
      expect(total_loss_row[8]).to eq('0.15')  # line_loss_1
      expect(total_loss_row[9]).to eq('0.15')  # line_loss_2
    end

    context 'when results directory already exists' do
      before do
        Dir.mkdir('results')
      end

      it 'does not raise an error' do
        expect { generator.generate_csv }.not_to raise_error
      end

      it 'still generates the CSV file correctly' do
        filename = generator.generate_csv
        expect(File.exist?(filename)).to be true
      end
    end
  end

  describe 'edge cases' do
    context 'with minimal data' do
      let(:minimal_results) do
        {
          num_of_buses: 1,
          types: [ 'Slack' ],
          v_data: [ 1.0 ],
          d_data: [ 0.0 ],
          p_data: [ 0.0 ],
          q_data: [ 0.0 ],
          del_degree: [ 0.0 ],
          z: [],
          p_injection: [ 0.0 ],
          q_injection: [ 0.0 ],
          power_generated: [ 0.0 ],
          reactive_generated: [ 0.0 ],
          pl_data: [ 0.0 ],
          ql_data: [ 0.0 ],
          totals: {
            pTotal: 0.0,
            qTotal: 0.0,
            pgTotal: 0.0,
            qgTotal: 0.0,
            plTotal: 0.0,
            qlTotal: 0.0
          },
          line_loss_1: 0.0,
          line_loss_2: 0.0
        }
      end

      subject(:minimal_generator) { described_class.new(minimal_results, timestamp) }

      it 'generates CSV successfully with single bus' do
        expect { minimal_generator.generate_csv }.not_to raise_error

        filename = minimal_generator.generate_csv
        expect(File.exist?(filename)).to be true

        csv_content = CSV.read(filename)
        expect(csv_content[1]).to eq([ '1', 'Slack', '1.0', '0.0', '0.0', '0.0' ])
      end
    end

    context 'with zero buses' do
      let(:zero_bus_results) do
        sample_results.merge(num_of_buses: 0, types: [], v_data: [], d_data: [],
                           p_data: [], q_data: [], del_degree: [], p_injection: [],
                           q_injection: [], power_generated: [], reactive_generated: [],
                           pl_data: [], ql_data: [])
      end

      subject(:zero_bus_generator) { described_class.new(zero_bus_results, timestamp) }

      it 'generates CSV with headers only' do
        filename = zero_bus_generator.generate_csv
        csv_content = CSV.read(filename)

        # Should have headers but no data rows for buses
        expect(csv_content[0]).to eq([ 'Bus Number', 'Type', 'V', 'D', 'P', 'Q' ])
        expect(csv_content[1]).to eq([])  # Empty row before detailed analysis
      end
    end
  end

  describe 'private methods' do
    describe '#ensure_results_directory_exists' do
      it 'creates results directory when it does not exist' do
        expect(Dir.exist?('results')).to be false

        generator.send(:ensure_results_directory_exists)

        expect(Dir.exist?('results')).to be true
      end

      it 'does not raise error when directory already exists' do
        Dir.mkdir('results')

        expect { generator.send(:ensure_results_directory_exists) }.not_to raise_error
      end
    end
  end
end
