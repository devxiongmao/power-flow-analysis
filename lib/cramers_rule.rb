# frozen_string_literal: true

require 'matrix'

class CramersRule
  def cramers_rule(a, terms)
    raise ArgumentError, ' Matrix not square' unless a.square?

    cols = a.to_a.transpose
    cols.each_index.map do |i|
      c = cols.dup
      c[i] = terms
      Matrix.columns(c).det / a.det
    end
  end
end
