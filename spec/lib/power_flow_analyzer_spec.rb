# frozen_string_literal: true

require_relative '../../lib/power_flow_analyzer'

RSpec.describe PowerFlowAnalyzer do
  let(:bus_data) do
    {
      num_of_buses: 3,
      params: {
        'type-1' => 'slack',
        'type-2' => 'generator',
        'type-3' => 'load',
        'v1' => '1.05', 'v2' => '1.04', 'v3' => '1.0',
        'd1' => '0.0', 'd2' => '0.0', 'd3' => '0.0',
        'pg1' => '0.0', 'pg2' => '40.0', 'pg3' => '0.0',
        'qg1' => '0.0', 'qg2' => '30.0', 'qg3' => '0.0',
        'pl1' => '0.0', 'pl2' => '20.0', 'pl3' => '45.0',
        'ql1' => '0.0', 'ql2' => '10.0', 'ql3' => '15.0',
        'qmin1' => '-40.0', 'qmin2' => '0.0', 'qmin3' => '-10.0',
        'qmax1' => '40.0', 'qmax2' => '50.0', 'qmax3' => '10.0'
      }
    }
  end

  let(:line_data) do
    {
      num_of_lines: 3
    }
  end

  let(:analyzer) { described_class.new(bus_data, line_data) }

  # Mock the dependencies
  let(:mock_y_bus_creator) { instance_double('YBusCreator') }
  let(:mock_y_bus) do
    [
      [ [ 0.5, 0.1 ], [ 0.2, 0.05 ], [ 0.1, 0.02 ] ],
      [ [ 0.2, 0.05 ], [ 0.6, 0.12 ], [ 0.15, 0.03 ] ],
      [ [ 0.1, 0.02 ], [ 0.15, 0.03 ], [ 0.4, 0.08 ] ]
    ]
  end
  let(:from_bus) { [ 0, 1, 0 ] }
  let(:to_bus) { [ 1, 2, 2 ] }

  before do
    allow(YBusCreator).to receive(:new).and_return(mock_y_bus_creator)
    allow(mock_y_bus_creator).to receive(:create_y_bus).and_return(mock_y_bus)
    allow(mock_y_bus_creator).to receive(:return_from_bus_list).and_return(from_bus)
    allow(mock_y_bus_creator).to receive(:return_to_bus_list).and_return(to_bus)
  end

  describe '#initialize' do
    it 'initializes with correct bus and line data' do
      expect(analyzer.instance_variable_get(:@bus_data)).to eq(bus_data)
      expect(analyzer.instance_variable_get(:@line_data)).to eq(line_data)
      expect(analyzer.instance_variable_get(:@num_of_buses)).to eq(3)
      expect(analyzer.instance_variable_get(:@num_of_lines)).to eq(3)
    end

    it 'initializes bus types correctly' do
      types = analyzer.instance_variable_get(:@types)
      expect(types[0]).to eq('Slack')
      expect(types[1]).to eq('Generator')
      expect(types[2]).to eq('Load')
    end

    it 'initializes voltage data correctly' do
      v_data = analyzer.instance_variable_get(:@v_data)
      expect(v_data[0]).to eq(1.05)
      expect(v_data[1]).to eq(1.04)
      expect(v_data[2]).to eq(1.0)
    end

    it 'initializes power data correctly' do
      p_data = analyzer.instance_variable_get(:@p_data)
      expect(p_data[0]).to eq(0.0) # (0 - 0) / 100
      expect(p_data[1]).to eq(0.2) # (40 - 20) / 100
      expect(p_data[2]).to eq(-0.45) # (0 - 45) / 100
    end

    it 'initializes reactive power data correctly' do
      q_data = analyzer.instance_variable_get(:@q_data)
      expect(q_data[0]).to eq(0.0) # (0 - 0) / 100
      expect(q_data[1]).to eq(0.2) # (30 - 10) / 100
      expect(q_data[2]).to eq(-0.15) # (0 - 15) / 100
    end
  end

  describe '#analyze' do
    let(:mock_cramer) { instance_double('CramersRule') }

    before do
      allow(CramersRule).to receive(:new).and_return(mock_cramer)
      # Mock the cramers_rule to return very small corrections to make iteration converge quickly
      allow(mock_cramer).to receive(:cramers_rule).and_return([ 0.0000001, 0.0000001, 0.0000001 ])

      # Mock the calculate_power_values method to return values that will converge quickly
      allow(analyzer).to receive(:calculate_power_values).and_return(
        [ analyzer.instance_variable_get(:@p_data), analyzer.instance_variable_get(:@q_data) ]
      )
    end

    it 'creates YBusCreator and gets Y-bus matrix' do
      expect(YBusCreator).to receive(:new).with(3, 3, bus_data[:params])
      expect(mock_y_bus_creator).to receive(:create_y_bus).with(3)
      expect(mock_y_bus_creator).to receive(:return_from_bus_list)
      expect(mock_y_bus_creator).to receive(:return_to_bus_list)

      analyzer.analyze
    end

    it 'returns a hash with expected keys' do
      result = analyzer.analyze

      expected_keys = [
        :num_of_buses, :types, :v_data, :d_data, :p_data, :q_data,
        :del_degree, :z, :p_injection, :q_injection, :power_generated,
        :reactive_generated, :totals, :y_bus, :from_bus, :to_bus,
        :pl_data, :ql_data, :line_loss_1, :line_loss_2
      ]

      expect(result.keys).to match_array(expected_keys)
    end

    it 'includes correct number of buses in result' do
      result = analyzer.analyze
      expect(result[:num_of_buses]).to eq(3)
    end

    it 'includes bus types in result' do
      result = analyzer.analyze
      expect(result[:types]).to eq([ 'Slack', 'Generator', 'Load' ])
    end
  end

  describe 'private methods' do
    describe '#count_load_buses' do
      it 'counts load buses correctly' do
        count = analyzer.send(:count_load_buses)
        expect(count).to eq(1)
      end
    end

    describe '#get_load_bus_numbers' do
      it 'returns correct load bus indices' do
        load_buses = analyzer.send(:get_load_bus_numbers)
        expect(load_buses).to eq([ 2 ])
      end
    end

    describe '#calculate_power_values' do
      it 'calculates power values for all buses' do
        p_values, q_values = analyzer.send(:calculate_power_values, mock_y_bus)

        expect(p_values).to be_an(Array)
        expect(q_values).to be_an(Array)
        expect(p_values.length).to eq(3)
        expect(q_values.length).to eq(3)
        expect(p_values).to all(be_a(Numeric))
        expect(q_values).to all(be_a(Numeric))
      end
    end

    describe '#build_error_vector' do
      let(:dP) { [ 0.1, 0.05 ] }
      let(:dQ) { [ 0.02 ] }

      it 'combines dP and dQ vectors correctly' do
        error_vector = analyzer.send(:build_error_vector, dP, dQ)
        expect(error_vector).to eq([ 0.1, 0.05, 0.02 ])
      end
    end

    describe '#calculate_voltage_magnitudes' do
      before do
        analyzer.instance_variable_set(:@v_data, [ 1.05, 1.04, 1.0 ])
        analyzer.instance_variable_set(:@d_data, [ 0.0, 0.1, -0.05 ])
      end

      it 'calculates voltage magnitudes correctly' do
        v_mag = analyzer.send(:calculate_voltage_magnitudes)

        expect(v_mag).to be_an(Array)
        expect(v_mag.length).to eq(3)
        v_mag.each do |vm|
          expect(vm).to be_an(Array)
          expect(vm.length).to eq(2)
          expect(vm[0]).to be_a(Numeric)
          expect(vm[1]).to be_a(Numeric)
        end
      end
    end

    describe '#calculate_angle_degrees' do
      before do
        analyzer.instance_variable_set(:@d_data, [ 0.0, 0.1, -0.05 ])
      end

      it 'converts radians to degrees correctly' do
        degrees = analyzer.send(:calculate_angle_degrees)

        expect(degrees).to be_an(Array)
        expect(degrees.length).to eq(3)
        expect(degrees[0]).to be_within(0.001).of(0.0)
        expect(degrees[1]).to be_within(0.001).of(5.729)
        expect(degrees[2]).to be_within(0.001).of(-2.865)
      end
    end

    describe '#calculate_totals' do
      before do
        analyzer.instance_variable_set(:@p_injection, [ 10.0, 20.0, 30.0 ])
        analyzer.instance_variable_set(:@q_injection, [ 5.0, 10.0, 15.0 ])
        analyzer.instance_variable_set(:@power_generated, [ 15.0, 25.0, 35.0 ])
        analyzer.instance_variable_set(:@reactive_generated, [ 8.0, 12.0, 18.0 ])
        analyzer.instance_variable_set(:@pl_data, [ 0.1, 0.2, 0.45 ])
        analyzer.instance_variable_set(:@ql_data, [ 0.0, 0.1, 0.15 ])
      end

      it 'calculates totals correctly' do
        totals = analyzer.send(:calculate_totals)

        expect(totals[:pTotal]).to eq(60.0)
        expect(totals[:qTotal]).to eq(30.0)
        expect(totals[:pgTotal]).to eq(75.0)
        expect(totals[:qgTotal]).to eq(38.0)
        expect(totals[:plTotal]).to eq(0.75)
        expect(totals[:qlTotal]).to eq(0.25)
      end
    end
  end

  describe 'edge cases and error handling' do
    context 'with single bus system' do
      let(:single_bus_data) do
        {
          num_of_buses: 1,
          params: {
            'type-1' => 'slack',
            'v1' => '1.0', 'd1' => '0.0',
            'pg1' => '0.0', 'qg1' => '0.0',
            'pl1' => '0.0', 'ql1' => '0.0',
            'qmin1' => '-10.0', 'qmax1' => '10.0'
          }
        }
      end

      let(:single_line_data) { { num_of_lines: 0 } }

      it 'handles single bus system' do
        single_analyzer = described_class.new(single_bus_data, single_line_data)
        expect(single_analyzer.instance_variable_get(:@num_of_buses)).to eq(1)
        expect(single_analyzer.instance_variable_get(:@types)[0]).to eq('Slack')
      end
    end

    context 'with missing bus type' do
      let(:invalid_bus_data) do
        {
          num_of_buses: 2,
          params: {
            'type-1' => 'invalid_type',
            'type-2' => 'load',
            'v1' => '1.0', 'v2' => '1.0',
            'd1' => '0.0', 'd2' => '0.0',
            'pg1' => '0.0', 'pg2' => '0.0',
            'qg1' => '0.0', 'qg2' => '0.0',
            'pl1' => '0.0', 'pl2' => '10.0',
            'ql1' => '0.0', 'ql2' => '5.0',
            'qmin1' => '-10.0', 'qmin2' => '-5.0',
            'qmax1' => '10.0', 'qmax2' => '5.0'
          }
        }
      end

      it 'defaults unknown bus type to Slack' do
        invalid_analyzer = described_class.new(invalid_bus_data, line_data)
        types = invalid_analyzer.instance_variable_get(:@types)
        expect(types[0]).to eq('Slack')
        expect(types[1]).to eq('Load')
      end
    end
  end

  describe 'integration test with mocked convergence' do
    let(:mock_cramer) { instance_double('CramersRule') }

    before do
      allow(CramersRule).to receive(:new).and_return(mock_cramer)
      # Mock convergence by returning small corrections
      allow(mock_cramer).to receive(:cramers_rule).and_return([ 0.000001, 0.000001, 0.000001 ])

      # Mock calculate_power_values to return values that will converge quickly
      allow(analyzer).to receive(:calculate_power_values).and_return(
        [ analyzer.instance_variable_get(:@p_data), analyzer.instance_variable_get(:@q_data) ]
      )
    end

    it 'completes full analysis workflow' do
      result = analyzer.analyze

      expect(result).to be_a(Hash)
      expect(result[:num_of_buses]).to eq(3)
      expect(result[:types]).to eq([ 'Slack', 'Generator', 'Load' ])
      expect(result[:v_data]).to all(be_a(Numeric))
      expect(result[:d_data]).to all(be_a(Numeric))
      expect(result[:totals]).to be_a(Hash)
      expect(result[:totals]).to have_key(:pTotal)
      expect(result[:totals]).to have_key(:qTotal)
    end
  end
end
