# frozen_string_literal: true

require_relative '../../lib/power_flow_service'
require_relative '../../lib/power_flow_analyzer'
require_relative '../../lib/csv_generator'
require_relative '../../lib/data_processor'

RSpec.describe PowerFlowService do
  subject(:service) { described_class.new }

  let(:mock_data_processor) { instance_double(DataProcessor) }
  let(:mock_analyzer) { instance_double(PowerFlowAnalyzer) }
  let(:mock_csv_generator) { instance_double(CsvGenerator) }

  before do
    allow(DataProcessor).to receive(:new).and_return(mock_data_processor)
  end

  describe '#initialize' do
    it 'creates a new DataProcessor instance' do
      expect(DataProcessor).to receive(:new)
      described_class.new
    end

    it 'assigns the data processor to instance variable' do
      expect(service.instance_variable_get(:@data_processor)).to eq(mock_data_processor)
    end
  end

  describe '#analyze_power_flow' do
    let(:params) do
      {
        'type_1' => 'Slack',
        'type_2' => 'PV',
        'type_3' => 'PQ',
        'from_1' => '1',
        'from_2' => '2',
        'voltage_1' => '1.05',
        'power_1' => '2.5'
      }
    end

    let(:counts) do
      {
        num_of_buses: 3,
        num_of_lines: 2
      }
    end

    let(:analysis_results) do
      {
        num_of_buses: 3,
        types: [ 'Slack', 'PV', 'PQ' ],
        v_data: [ 1.05, 1.02, 0.98 ],
        d_data: [ 0.0, -2.5, -5.2 ],
        p_data: [ 2.5, 1.8, -1.2 ],
        q_data: [ 1.2, 0.8, -0.6 ],
        totals: { pTotal: 3.1, qTotal: 1.4 }
      }
    end

    let(:csv_filename) { 'results/PowerFlowAnalysis-NR-01-12-2024-14-30-22.csv' }
    let(:timestamp) { '01-12-2024-14-30-22' }

    before do
      allow(mock_data_processor).to receive(:count_entities).with(params).and_return(counts)
      allow(PowerFlowAnalyzer).to receive(:new).and_return(mock_analyzer)
      allow(mock_analyzer).to receive(:analyze).and_return(analysis_results)
      allow(CsvGenerator).to receive(:new).and_return(mock_csv_generator)
      allow(mock_csv_generator).to receive(:generate_csv).and_return(csv_filename)
      allow(Time).to receive(:now).and_return(double('time', strftime: timestamp))
    end

    it 'counts entities using the data processor' do
      expect(mock_data_processor).to receive(:count_entities).with(params)
      service.analyze_power_flow(params)
    end

    it 'creates PowerFlowAnalyzer with correct bus and line data' do
      expected_bus_data = {
        num_of_buses: 3,
        params: params
      }
      expected_line_data = {
        num_of_lines: 2
      }

      expect(PowerFlowAnalyzer).to receive(:new).with(expected_bus_data, expected_line_data)
      service.analyze_power_flow(params)
    end

    it 'performs analysis using the analyzer' do
      expect(mock_analyzer).to receive(:analyze)
      service.analyze_power_flow(params)
    end

    it 'creates CsvGenerator with analysis results and timestamp' do
      expect(CsvGenerator).to receive(:new).with(analysis_results, timestamp)
      service.analyze_power_flow(params)
    end

    it 'generates CSV file using the generator' do
      expect(mock_csv_generator).to receive(:generate_csv)
      service.analyze_power_flow(params)
    end

    it 'returns hash with results, filename, and timestamp' do
      result = service.analyze_power_flow(params)

      expect(result).to be_a(Hash)
      expect(result).to have_key(:results)
      expect(result).to have_key(:filename)
      expect(result).to have_key(:time)
      expect(result[:results]).to eq(analysis_results)
      expect(result[:filename]).to eq(csv_filename)
      expect(result[:time]).to eq(timestamp)
    end

    it 'generates timestamp in correct format' do
      time_double = double('time')
      expect(Time).to receive(:now).and_return(time_double)
      expect(time_double).to receive(:strftime).with("%d-%m-%Y-%H-%M-%S").and_return(timestamp)
      service.analyze_power_flow(params)
    end

    context 'with minimal parameters' do
      let(:minimal_params) { { 'type_1' => 'Slack' } }
      let(:minimal_counts) { { num_of_buses: 1, num_of_lines: 0 } }
      let(:minimal_results) { { num_of_buses: 1, types: [ 'Slack' ] } }

      before do
        allow(mock_data_processor).to receive(:count_entities).with(minimal_params).and_return(minimal_counts)
        allow(mock_analyzer).to receive(:analyze).and_return(minimal_results)
      end

      it 'handles minimal parameter set correctly' do
        result = service.analyze_power_flow(minimal_params)

        expect(result[:results]).to eq(minimal_results)
        expect(result[:filename]).to eq(csv_filename)
        expect(result[:time]).to eq(timestamp)
      end
    end

    context 'with no bus or line parameters' do
      let(:empty_params) { { 'voltage_1' => '1.0', 'other_param' => 'value' } }
      let(:empty_counts) { { num_of_buses: 0, num_of_lines: 0 } }
      let(:empty_results) { { num_of_buses: 0, types: [] } }

      before do
        allow(mock_data_processor).to receive(:count_entities).with(empty_params).and_return(empty_counts)
        allow(mock_analyzer).to receive(:analyze).and_return(empty_results)
      end

      it 'handles parameters with no buses or lines' do
        result = service.analyze_power_flow(empty_params)

        expect(result[:results]).to eq(empty_results)
        expect(result[:filename]).to eq(csv_filename)
        expect(result[:time]).to eq(timestamp)
      end
    end

    context 'when PowerFlowAnalyzer raises an error' do
      before do
        allow(mock_analyzer).to receive(:analyze).and_raise(StandardError, 'Analysis failed')
      end

      it 'propagates the error from analyzer' do
        expect { service.analyze_power_flow(params) }.to raise_error(StandardError, 'Analysis failed')
      end
    end

    context 'when CsvGenerator raises an error' do
      before do
        allow(mock_csv_generator).to receive(:generate_csv).and_raise(StandardError, 'CSV generation failed')
      end

      it 'propagates the error from CSV generator' do
        expect { service.analyze_power_flow(params) }.to raise_error(StandardError, 'CSV generation failed')
      end
    end
  end

  describe '#process_csv_files' do
    let(:bus_file) { { tempfile: double('tempfile', read: 'bus,data') } }
    let(:line_file) { { tempfile: double('tempfile', read: 'line,data') } }
    let(:processed_data) do
      {
        bus_data: [ '1', 'Slack', '1.05', '0.0' ],
        line_data: [ '1', '2', '0.02', '0.06' ]
      }
    end

    before do
      allow(mock_data_processor).to receive(:process_csv_files).with(bus_file, line_file).and_return(processed_data)
    end

    it 'delegates CSV processing to the data processor' do
      expect(mock_data_processor).to receive(:process_csv_files).with(bus_file, line_file)
      service.process_csv_files(bus_file, line_file)
    end

    it 'returns the processed data from data processor' do
      result = service.process_csv_files(bus_file, line_file)
      expect(result).to eq(processed_data)
    end

    context 'when data processor raises an error' do
      before do
        allow(mock_data_processor).to receive(:process_csv_files).and_raise(StandardError, 'CSV processing failed')
      end

      it 'propagates the error from data processor' do
        expect { service.process_csv_files(bus_file, line_file) }.to raise_error(StandardError, 'CSV processing failed')
      end
    end

    context 'with nil files' do
      it 'passes nil files to data processor' do
        expect(mock_data_processor).to receive(:process_csv_files).with(nil, nil)
        service.process_csv_files(nil, nil)
      end
    end
  end

  describe 'integration workflow' do
    let(:params) do
      {
        'type_1' => 'Slack',
        'type_2' => 'PV',
        'from_1' => '1'
      }
    end

    let(:bus_file) { { tempfile: double('tempfile') } }
    let(:line_file) { { tempfile: double('tempfile') } }

    it 'can process CSV files and then analyze power flow independently' do
      # Mock CSV processing
      csv_data = { bus_data: [ 'data' ], line_data: [ 'data' ] }
      allow(mock_data_processor).to receive(:process_csv_files).and_return(csv_data)

      # Mock power flow analysis
      counts = { num_of_buses: 2, num_of_lines: 1 }
      results = { num_of_buses: 2, types: [ 'Slack', 'PV' ] }
      filename = 'test.csv'
      timestamp = '01-01-2024-12-00-00'

      allow(mock_data_processor).to receive(:count_entities).and_return(counts)
      allow(PowerFlowAnalyzer).to receive(:new).and_return(mock_analyzer)
      allow(mock_analyzer).to receive(:analyze).and_return(results)
      allow(CsvGenerator).to receive(:new).and_return(mock_csv_generator)
      allow(mock_csv_generator).to receive(:generate_csv).and_return(filename)
      allow(Time).to receive(:now).and_return(double('time', strftime: timestamp))

      # Test both methods work independently
      csv_result = service.process_csv_files(bus_file, line_file)
      analysis_result = service.analyze_power_flow(params)

      expect(csv_result).to eq(csv_data)
      expect(analysis_result[:results]).to eq(results)
      expect(analysis_result[:filename]).to eq(filename)
    end
  end

  describe 'dependency injection' do
    it 'uses the same data processor instance for multiple operations' do
      allow(mock_data_processor).to receive(:process_csv_files).and_return({})
      allow(mock_data_processor).to receive(:count_entities).and_return({ num_of_buses: 0, num_of_lines: 0 })
      allow(PowerFlowAnalyzer).to receive(:new).and_return(mock_analyzer)
      allow(mock_analyzer).to receive(:analyze).and_return({})
      allow(CsvGenerator).to receive(:new).and_return(mock_csv_generator)
      allow(mock_csv_generator).to receive(:generate_csv).and_return('test.csv')
      allow(Time).to receive(:now).and_return(double('time', strftime: 'timestamp'))

      service.process_csv_files({}, {})
      service.analyze_power_flow({})

      # Verify the same data processor instance is used
      expect(service.instance_variable_get(:@data_processor)).to eq(mock_data_processor)
    end
  end
end
