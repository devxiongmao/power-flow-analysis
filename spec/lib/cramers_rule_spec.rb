# frozen_string_literal: true

require_relative '../../lib/cramers_rule'
require 'matrix'

RSpec.describe CramersRule do
  subject(:solver) { described_class.new }

  describe '#cramers_rule' do
    it 'solves a 2x2 system correctly' do
      a = Matrix[[ 2, 3 ], [ 1, 2 ]]
      terms = [ 5, 3 ]

      expected_solution = [ 1.0, 1.0 ]  # Solves: 2x + 3y = 5, 1x + 2y = 3

      expect(solver.cramers_rule(a, terms)).to eq(expected_solution)
    end

    it 'solves a 3x3 system correctly' do
      a = Matrix[[ 2, -1, 3 ], [ 1, 0, -2 ], [ 3, 2, -4 ]]
      terms = [ 5, -3, 2 ]

      expected_solution = [ 1, 3, 2 ]  # Solves: 2x - y + 3z = 5, etc.

      expect(solver.cramers_rule(a, terms)).to eq(expected_solution)
    end

    it 'raises an error when given a non-square matrix' do
      a = Matrix[[ 2, 3, 1 ], [ 1, 2, 4 ]]  # 2x3 matrix (not square)
      terms = [ 5, 3 ]

      expect { solver.cramers_rule(a, terms) }.to raise_error(ArgumentError, ' Matrix not square')
    end

    it 'raises an error when determinant is zero (no unique solution)' do
      a = Matrix[[ 1, 2 ], [ 2, 4 ]]  # Determinant is 0 (linearly dependent)
      terms = [ 3, 6 ]

      expect { solver.cramers_rule(a, terms) }.to raise_error(ZeroDivisionError)
    end
  end
end
