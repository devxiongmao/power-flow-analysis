# frozen_string_literal: true

require_relative '../../lib/polar_to_rect'

RSpec.describe PolarToRectangular do
  subject(:converter) { described_class.new }

  describe '#main' do
    it 'converts polar coordinates to rectangular correctly' do
      v_data = [ 1.0, 2.0, 3.0 ]  # Magnitudes
      d_data = [ 0, Math::PI / 2, Math::PI ]  # Angles in radians

      expected_output = [ [ 1.0, 0.0 ], [ 1.2246467991473532e-16, 2.0 ], [ -3.0, 3.6739403974420594e-16 ] ]

      result = converter.main(v_data, d_data)
      expect(result).to eq(expected_output)
    end

    it 'returns an empty array when given empty inputs' do
      expect(converter.main([], [])).to eq([])
    end

    it 'handles single-element inputs' do
      v_data = [ 2.0 ]
      d_data = [ Math::PI / 4 ]  # 45 degrees

      expected_output = [ [ 2.0 * Math.cos(Math::PI / 4), 2.0 * Math.sin(Math::PI / 4) ] ]

      expect(converter.main(v_data, d_data)).to eq(expected_output)
    end

    it 'raises an error if v_data and d_data have different sizes' do
      v_data = [ 1.0, 2.0 ]
      d_data = [ 0 ]  # Mismatched size

      expect { converter.main(v_data, d_data) }.to raise_error(RuntimeError)
    end
  end
end
