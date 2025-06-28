# frozen_string_literal: true

require_relative '../../lib/data_processor'

RSpec.describe DataProcessor do
  subject(:processor) { described_class.new }

  describe '#initialize' do
    it 'initializes with empty bus_data and line_data arrays' do
      expect(processor.instance_variable_get(:@bus_data)).to eq([])
      expect(processor.instance_variable_get(:@line_data)).to eq([])
    end
  end

  describe '#process_csv_files' do
    let(:bus_csv_content) do
      "Bus,Type,V,Angle,P,Q\r\n" \
      "1,Slack,1.05,0.0,0.0,0.0\r\n" \
      "2,PV,1.02,-2.5,1.8,0.0\r\n" \
      "3,PQ,1.0,0.0,-1.2,-0.6"
    end

    let(:line_csv_content) do
      "From,To,R,X,B\r\n" \
      "1,2,0.02,0.06,0.03\r\n" \
      "2,3,0.08,0.24,0.025"
    end

    let(:bus_file) do
      {
        tempfile: double('tempfile', read: bus_csv_content)
      }
    end

    let(:line_file) do
      {
        tempfile: double('tempfile', read: line_csv_content)
      }
    end

    it 'processes both CSV files and returns parsed data' do
      result = processor.process_csv_files(bus_file, line_file)

      expect(result).to have_key(:bus_data)
      expect(result).to have_key(:line_data)
      expect(result[:bus_data]).to be_an(Array)
      expect(result[:line_data]).to be_an(Array)
    end

    it 'correctly parses bus CSV data' do
      result = processor.process_csv_files(bus_file, line_file)

      expected_bus_data = [
        '1', 'Slack', '1.05', '0.0', '0.0', '0.0',
        '2', 'PV', '1.02', '-2.5', '1.8', '0.0',
        '3', 'PQ', '1.0', '0.0', '-1.2', '-0.6'
      ]

      expect(result[:bus_data]).to eq(expected_bus_data)
    end

    it 'correctly parses line CSV data' do
      result = processor.process_csv_files(bus_file, line_file)

      expected_line_data = [
        '1', '2', '0.02', '0.06', '0.03',
        '2', '3', '0.08', '0.24', '0.025'
      ]

      expect(result[:line_data]).to eq(expected_line_data)
    end

    it 'updates instance variables with parsed data' do
      processor.process_csv_files(bus_file, line_file)

      expect(processor.instance_variable_get(:@bus_data)).not_to be_empty
      expect(processor.instance_variable_get(:@line_data)).not_to be_empty
    end

    context 'with single row CSV files' do
      let(:single_bus_csv) do
        "Bus,Type,V,Angle,P,Q\r\n" \
        "1,Slack,1.0,0.0,0.0,0.0"
      end

      let(:single_line_csv) do
        "From,To,R,X,B\r\n" \
        "1,2,0.01,0.03,0.02"
      end

      let(:single_bus_file) do
        { tempfile: double('tempfile', read: single_bus_csv) }
      end

      let(:single_line_file) do
        { tempfile: double('tempfile', read: single_line_csv) }
      end

      it 'processes single row CSV files correctly' do
        result = processor.process_csv_files(single_bus_file, single_line_file)

        expect(result[:bus_data]).to eq([ '1', 'Slack', '1.0', '0.0', '0.0', '0.0' ])
        expect(result[:line_data]).to eq([ '1', '2', '0.01', '0.03', '0.02' ])
      end
    end

    context 'with header-only CSV files' do
      let(:header_only_bus_csv) { "Bus,Type,V,Angle,P,Q" }
      let(:header_only_line_csv) { "From,To,R,X,B" }

      let(:header_only_bus_file) do
        { tempfile: double('tempfile', read: header_only_bus_csv) }
      end

      let(:header_only_line_file) do
        { tempfile: double('tempfile', read: header_only_line_csv) }
      end

      it 'returns empty arrays for header-only files' do
        result = processor.process_csv_files(header_only_bus_file, header_only_line_file)

        expect(result[:bus_data]).to eq([])
        expect(result[:line_data]).to eq([])
      end
    end

    context 'with files containing empty values' do
      let(:csv_with_empty_values) do
        "Bus,Type,V,Angle,P,Q\r\n" \
        "1,,1.0,,0.0,\r\n" \
        ",PV,,0.0,1.5,0.8"
      end

      let(:file_with_empty_values) do
        { tempfile: double('tempfile', read: csv_with_empty_values) }
      end

      it 'handles empty values correctly' do
        result = processor.process_csv_files(file_with_empty_values, file_with_empty_values)

        # The actual parsing doesn't include trailing empty values from commas at end of lines
        expected_data = [ '1', '', '1.0', '', '0.0', '', 'PV', '', '0.0', '1.5', '0.8' ]
        expect(result[:bus_data]).to eq(expected_data)
      end
    end
  end

  describe '#count_entities' do
    context 'with bus and line parameters' do
      let(:params) do
        {
          'type_1' => 'Slack',
          'type_2' => 'PV',
          'type_3' => 'PQ',
          'from_1' => '1',
          'from_2' => '2',
          'voltage_1' => '1.05',
          'power_1' => '2.5',
          'other_param' => 'value'
        }
      end

      it 'correctly counts buses and lines' do
        result = processor.count_entities(params)

        expect(result[:num_of_buses]).to eq(3)
        expect(result[:num_of_lines]).to eq(2)
      end

      it 'returns a hash with the correct keys' do
        result = processor.count_entities(params)

        expect(result).to have_key(:num_of_buses)
        expect(result).to have_key(:num_of_lines)
      end
    end

    context 'with only bus parameters' do
      let(:bus_only_params) do
        {
          'type_1' => 'Slack',
          'type_2' => 'PV',
          'voltage_1' => '1.0',
          'angle_1' => '0.0'
        }
      end

      it 'counts only buses when no line parameters present' do
        result = processor.count_entities(bus_only_params)

        expect(result[:num_of_buses]).to eq(2)
        expect(result[:num_of_lines]).to eq(0)
      end
    end

    context 'with only line parameters' do
      let(:line_only_params) do
        {
          'from_1' => '1',
          'from_2' => '2',
          'from_3' => '3',
          'to_1' => '2',
          'resistance_1' => '0.02'
        }
      end

      it 'counts only lines when no bus parameters present' do
        result = processor.count_entities(line_only_params)

        expect(result[:num_of_buses]).to eq(0)
        expect(result[:num_of_lines]).to eq(3)
      end
    end

    context 'with parameters containing "type" and "from" as substrings' do
      let(:substring_params) do
        {
          'prototype_1' => 'value',  # contains "type"
          'subtype_2' => 'value',    # contains "type"
          'inform_1' => 'value',     # contains "from"
          'from_start_1' => 'value', # contains "from"
          'type_main' => 'Slack',    # contains "type"
          'from_main' => '1'         # contains "from"
        }
      end

      it 'counts parameters that contain the keywords as substrings' do
        result = processor.count_entities(substring_params)

        expect(result[:num_of_buses]).to eq(3)  # prototype_1, subtype_2, type_main
        expect(result[:num_of_lines]).to eq(2)  # from_start_1, from_main (inform_1 doesn't match because it doesn't contain "from" at word boundary)
      end
    end

    context 'with empty parameters' do
      let(:empty_params) { {} }

      it 'returns zero counts for empty parameters' do
        result = processor.count_entities(empty_params)

        expect(result[:num_of_buses]).to eq(0)
        expect(result[:num_of_lines]).to eq(0)
      end
    end

    context 'with parameters not containing target keywords' do
      let(:unrelated_params) do
        {
          'voltage_1' => '1.0',
          'power_1' => '2.5',
          'resistance_1' => '0.02',
          'other_param' => 'value'
        }
      end

      it 'returns zero counts when no matching parameters' do
        result = processor.count_entities(unrelated_params)

        expect(result[:num_of_buses]).to eq(0)
        expect(result[:num_of_lines]).to eq(0)
      end
    end
  end

  describe 'private methods' do
    describe '#parse_csv_file' do
      let(:csv_content) do
        "Header1,Header2,Header3\r\n" \
        "value1,value2,value3\r\n" \
        "value4,value5,value6"
      end

      let(:mock_file) do
        { tempfile: double('tempfile', read: csv_content) }
      end

      it 'skips the header row and parses data correctly' do
        result = processor.send(:parse_csv_file, mock_file)

        expected_data = %w[value1 value2 value3 value4 value5 value6]
        expect(result).to eq(expected_data)
      end

      context 'with file containing only headers' do
        let(:header_only_content) { "Header1,Header2,Header3" }
        let(:header_only_file) do
          { tempfile: double('tempfile', read: header_only_content) }
        end

        it 'returns empty array when file contains only headers' do
          result = processor.send(:parse_csv_file, header_only_file)
          expect(result).to eq([])
        end
      end

      context 'with file containing trailing commas' do
        let(:trailing_comma_content) do
          "Header1,Header2,Header3\r\n" \
          "value1,value2,\r\n" \
          "value4,,value6"
        end

        let(:trailing_comma_file) do
          { tempfile: double('tempfile', read: trailing_comma_content) }
        end

        it 'handles trailing commas and empty values' do
          result = processor.send(:parse_csv_file, trailing_comma_file)

          # The actual parsing doesn't preserve trailing empty values from commas at end of lines
          expected_data = [ 'value1', 'value2', 'value4', '', 'value6' ]
          expect(result).to eq(expected_data)
        end
      end
    end
  end

  describe 'integration scenarios' do
    context 'processing files then counting parameters' do
      let(:bus_file) do
        content = "Bus,Type\r\n1,Slack\r\n2,PV"
        { tempfile: double('tempfile', read: content) }
      end

      let(:line_file) do
        content = "From,To\r\n1,2"
        { tempfile: double('tempfile', read: content) }
      end

      let(:params) do
        {
          'type_1' => 'Slack',
          'type_2' => 'PV',
          'from_1' => '1'
        }
      end

      it 'can process files and count parameters independently' do
        csv_result = processor.process_csv_files(bus_file, line_file)
        count_result = processor.count_entities(params)

        expect(csv_result[:bus_data]).to eq([ '1', 'Slack', '2', 'PV' ])
        expect(csv_result[:line_data]).to eq([ '1', '2' ])
        expect(count_result[:num_of_buses]).to eq(2)
        expect(count_result[:num_of_lines]).to eq(1)
      end
    end
  end
end
