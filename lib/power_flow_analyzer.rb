# frozen_string_literal: true

require_relative 'cramers_rule'
require_relative 'y_bus_creator'
require 'matrix'

# Handles the core power flow analysis using Newton-Raphson method
class PowerFlowAnalyzer
  def initialize(bus_data, line_data)
    @bus_data = bus_data
    @line_data = line_data
    @num_of_buses = bus_data[:num_of_buses]
    @num_of_lines = line_data[:num_of_lines]
    @params = bus_data[:params]
    
    @types = []
    @v_data = []
    @d_data = []
    @pg_data = []
    @qg_data = []
    @pl_data = []
    @ql_data = []
    @qmin = []
    @qmax = []
    @p_data = []
    @q_data = []
    
    initialize_bus_data
  end

  def analyze
    y_bus_creator = YBusCreator.new(@num_of_buses, @num_of_lines, @params)
    y_bus = y_bus_creator.create_y_bus(@num_of_buses)
    from_bus = y_bus_creator.return_from_bus_list
    to_bus = y_bus_creator.return_to_bus_list

    perform_newton_raphson_iteration(y_bus)
    calculate_final_results(y_bus, from_bus, to_bus)
    
    build_results_hash(y_bus, from_bus, to_bus)
  end

  private

  def initialize_bus_data
    pv_bus_numbers = []
    load_bus_numbers = []

    @num_of_buses.times do |i|
      if @params["type-#{i + 1}"] == 'generator'
        @types[i] = 'Generator'
        pv_bus_numbers.push(i)
      elsif @params["type-#{i + 1}"] == 'load'
        @types[i] = 'Load'
        load_bus_numbers.push(i)
      else # for Slack busses
        @types[i] = 'Slack'
        pv_bus_numbers.push(i)
      end

      @v_data[i] = @params["v#{i + 1}"].to_f
      @d_data[i] = @params["d#{i + 1}"].to_f
      @pg_data[i] = @params["pg#{i + 1}"].to_f / 100
      @qg_data[i] = @params["qg#{i + 1}"].to_f / 100
      @pl_data[i] = @params["pl#{i + 1}"].to_f / 100
      @ql_data[i] = @params["ql#{i + 1}"].to_f / 100
      @qmin[i] = @params["qmin#{i + 1}"].to_f / 100
      @qmax[i] = @params["qmax#{i + 1}"].to_f / 100
      @p_data[i] = (@params["pg#{i + 1}"].to_f - @params["pl#{i + 1}"].to_f) / 100
      @q_data[i] = (@params["qg#{i + 1}"].to_f - @params["ql#{i + 1}"].to_f) / 100
    end
  end

  def perform_newton_raphson_iteration(y_bus)
    p_specified = @p_data
    q_specified = @q_data
    tolerance = 1
    iteration_num = 1

    while tolerance > 0.000001
      processing_p_values, processing_q_values = calculate_power_values(y_bus)
      
      adjust_generator_voltages(processing_q_values, iteration_num)
      
      dPa, dQa = calculate_power_mismatches(p_specified, q_specified, processing_p_values, processing_q_values)
      
      dP, dQ = build_mismatch_vectors(dPa, dQa)
      
      error_vector = build_error_vector(dP, dQ)
      
      jacobian = build_jacobian_matrix(y_bus, dQ.length)
      
      correction_vector = solve_jacobian_equation(jacobian, error_vector)
      
      update_voltage_and_angle_values(correction_vector, dQ.length)
      
      iteration_num += 1
      absolute = error_vector.map { |value| value.negative? ? -1 * value : value }
      tolerance = absolute.max
    end
    
    @p_data = processing_p_values
    @q_data = processing_q_values
  end

  def calculate_power_values(y_bus)
    processing_p_values = Array.new(@num_of_buses, 0)
    processing_q_values = Array.new(@num_of_buses, 0)

    @num_of_buses.times do |i|
      @num_of_buses.times do |k|
        processing_p_values[i] += @v_data[i] * @v_data[k] * 
          (y_bus[i][k][0] * Math.cos(@d_data[i] - @d_data[k]) + 
           y_bus[i][k][1] * Math.sin(@d_data[i] - @d_data[k]))
        
        processing_q_values[i] += @v_data[i] * @v_data[k] * 
          (y_bus[i][k][0] * Math.sin(@d_data[i] - @d_data[k]) - 
           y_bus[i][k][1] * Math.cos(@d_data[i] - @d_data[k]))
      end
    end

    [processing_p_values, processing_q_values]
  end

  def adjust_generator_voltages(processing_q_values, iteration_num)
    return unless (iteration_num <= 7) && (iteration_num > 2)

    @num_of_buses.times do |n|
      next if n.zero?
      next unless @types[n] == 'Generator'

      qg = processing_q_values[n] + @ql_data[n]
      if qg < @qmin[n]
        @v_data[n] += 0.01
      elsif qg > @qmax[n]
        @v_data[n] -= 0.01
      end
    end
  end

  def calculate_power_mismatches(p_specified, q_specified, processing_p_values, processing_q_values)
    dPa = []
    dQa = []
    
    p_specified.each_with_index do |value, i|
      dPa[i] = value - processing_p_values[i]
      dQa[i] = q_specified[i] - processing_q_values[i]
    end
    
    [dPa, dQa]
  end

  def build_mismatch_vectors(dPa, dQa)
    k = 0
    dQ = Array.new(count_load_buses, 0)

    @num_of_buses.times do |i|
      if @params["type-#{i + 1}"] == 'load'
        dQ[k] = dQa[i]
        k += 1
      end
    end

    dP = []
    @num_of_buses.times do |i|
      next if i.zero?
      dP.push(dPa[i])
    end

    [dP, dQ]
  end

  def build_error_vector(dP, dQ)
    error_vector = []
    dP.each { |value| error_vector.push(value) }
    dQ.each { |value| error_vector.push(value) }
    error_vector
  end

  def build_jacobian_matrix(y_bus, num_of_load_buses)
    j1 = build_j1_matrix(y_bus)
    j2 = build_j2_matrix(y_bus, num_of_load_buses)
    j3 = build_j3_matrix(y_bus, num_of_load_buses)
    j4 = build_j4_matrix(y_bus, num_of_load_buses)
    
    combine_jacobian_submatrices(j1, j2, j3, j4, num_of_load_buses)
  end

  def build_j1_matrix(y_bus)
    j1 = Array.new(@num_of_buses - 1) { Array.new(@num_of_buses - 1, 0) }

    (@num_of_buses - 1).times do |i|
      m = i + 1
      (@num_of_buses - 1).times do |k|
        n = k + 1
        if n == m
          @num_of_buses.times do |n|
            j1[i][k] += @v_data[m] * @v_data[n] * 
              (-y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) + 
               y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
          end
          j1[i][k] -= y_bus[m][m][1] * @v_data[m]**2
        else
          j1[i][k] = @v_data[m] * @v_data[n] * 
            (y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) - 
             y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
        end
      end
    end
    
    j1
  end

  def build_j2_matrix(y_bus, num_of_load_buses)
    j2 = Array.new(@num_of_buses - 1) { Array.new(num_of_load_buses, 0) }
    load_bus_numbers = get_load_bus_numbers

    (@num_of_buses - 1).times do |i|
      m = i + 1
      num_of_load_buses.times do |k|
        n = load_bus_numbers[k]
        if n == m
          @num_of_buses.times do |n|
            j2[i][k] += @v_data[n] * 
              (y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) + 
               y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
          end
          j2[i][k] += y_bus[m][m][0] * @v_data[m]
        else
          j2[i][k] = @v_data[m] * 
            (y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) + 
             y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
        end
      end
    end
    
    j2
  end

  def build_j3_matrix(y_bus, num_of_load_buses)
    j3 = Array.new(num_of_load_buses) { Array.new(@num_of_buses - 1, 0) }
    load_bus_numbers = get_load_bus_numbers

    num_of_load_buses.times do |i|
      m = load_bus_numbers[i]
      (@num_of_buses - 1).times do |k|
        n = k + 1
        if n == m
          @num_of_buses.times do |n|
            j3[i][k] += @v_data[m] * @v_data[n] * 
              (y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) + 
               y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
          end
          j3[i][k] -= y_bus[m][m][0] * @v_data[m]**2
        else
          j3[i][k] = @v_data[m] * @v_data[n] * 
            (-y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) - 
             y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
        end
      end
    end
    
    j3
  end

  def build_j4_matrix(y_bus, num_of_load_buses)
    j4 = Array.new(num_of_load_buses) { Array.new(num_of_load_buses, 0) }
    load_bus_numbers = get_load_bus_numbers

    num_of_load_buses.times do |i|
      m = load_bus_numbers[i]
      num_of_load_buses.times do |k|
        n = load_bus_numbers[k]
        if n == m
          @num_of_buses.times do |n|
            j4[i][k] += @v_data[n] * 
              (y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) - 
               y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
          end
          j4[i][k] -= y_bus[m][m][1] * @v_data[m]
        else
          j4[i][k] = @v_data[m] * 
            (y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) - 
             y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
        end
      end
    end
    
    j4
  end

  def combine_jacobian_submatrices(j1, j2, j3, j4, num_of_load_buses)
    jacobian = Array.new(@num_of_buses + num_of_load_buses - 1) { [] }

    # Add J1 and J2 to first rows
    j1.each_with_index do |row_j1, i|
      row_j1.each { |value| jacobian[i].push(value) }
    end

    j2.each_with_index do |row_j2, i|
      row_j2.each { |value| jacobian[i].push(value) }
    end

    # Add J3 and J4 to remaining rows
    j3.each_with_index do |row_j3, i|
      k = @num_of_buses + i - 1
      row_j3.each { |value| jacobian[k].push(value) }
    end

    j4.each_with_index do |row_j4, i|
      k = @num_of_buses + i - 1
      row_j4.each { |value| jacobian[k].push(value) }
    end

    jacobian
  end

  def solve_jacobian_equation(jacobian, error_vector)
    matrix = Matrix[*jacobian]
    cramer = CramersRule.new
    cramer.cramers_rule(matrix, error_vector)
  end

  def update_voltage_and_angle_values(correction_vector, num_of_load_buses)
    # Update angles
    @num_of_buses.times do |i|
      next if i.zero?
      @d_data[i] = correction_vector[i - 1] + @d_data[i]
    end

    # Update voltages for load buses
    k = 0
    @num_of_buses.times do |i|
      next if i.zero?
      if @params["type-#{i + 1}"] == 'load'
        @v_data[i] = correction_vector[@num_of_buses - 1 + k] + @v_data[i]
        k += 1
      end
    end
  end

  def calculate_final_results(y_bus, from_bus, to_bus)
    @vMag = calculate_voltage_magnitudes
    @del_degree = calculate_angle_degrees
    @z = calculate_line_flows(y_bus, from_bus, to_bus)
    @p_injection, @q_injection = calculate_power_injections(y_bus)
    @power_generated, @reactive_generated = calculate_generated_power
    @totals = calculate_totals
  end

  def calculate_voltage_magnitudes
    vMag = Array.new(@num_of_buses) { [0, 0] }
    
    @num_of_buses.times do |i|
      vMag[i][0] = @v_data[i] * Math.cos(@d_data[i])
      vMag[i][1] = @v_data[i] * Math.sin(@d_data[i])
    end
    
    vMag
  end

  def calculate_angle_degrees
    @num_of_buses.times.map do |i|
      (180 * @d_data[i]) / Math::PI
    end
  end

  def calculate_line_flows(y_bus, from_bus, to_bus)
    z = []
    iij = []
    sij = []
    si = []

    @num_of_buses.times do |i|
      z[i] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      si[i] = 0
    end

    @num_of_buses.times do |i|
      iij[i] = []
      sij[i] = []
      @num_of_buses.times do |j|
        iij[i][j] = [0, 0]
        sij[i][j] = [0, 0]
      end
    end

    i_matrix = []

    # BUS CURRENT INJECTIONS
    @num_of_buses.times do |i|
      i_matrix[i] = [0, 0]

      @num_of_buses.times do |j|
        i_matrix[i][0] += (y_bus[i][j][0] * @vMag[j][0] - y_bus[i][j][1] * @vMag[j][1])
        i_matrix[i][1] += (y_bus[i][j][1] * @vMag[j][0] + y_bus[i][j][0] * @vMag[j][1])
      end
    end

    iAngle = []
    iMag = []
    @num_of_buses.times do |i|
      iMag[i] = (i_matrix[i][0]**2 + i_matrix[i][1]**2)**0.5
      iAngle[i] = Math.atan(i_matrix[i][1] / i_matrix[i][0])
    end

    # LINE CURRENT FLOWS
    @num_of_lines.times do |m|
      val_p = from_bus[m]
      val_q = to_bus[m]
      real_part = @vMag[val_p][0] - @vMag[val_q][0]
      imag_part = @vMag[val_p][1] - @vMag[val_q][1]
      iij[val_p][val_q][0] = -1 * (real_part * y_bus[val_p][val_q][0] - imag_part * y_bus[val_p][val_q][1])
      iij[val_p][val_q][1] = -1 * (real_part * y_bus[val_p][val_q][1] + imag_part * y_bus[val_p][val_q][0])
      iij[val_q][val_p][0] = -1 * iij[val_p][val_q][0]
      iij[val_q][val_p][1] = -1 * iij[val_p][val_q][1]
    end

    iijMag = []
    iijAngle = []

    @num_of_buses.times do |i|
      iijMag[i] = []
      iijAngle[i] = []
      @num_of_buses.times do |j|
        iijMag[i][j] = (iij[i][j][0]**2 + iij[i][j][1]**2)**0.5
        iijAngle[i][j] = Math.atan(iij[i][j][1] / iij[i][j][0].to_f)
      end
    end

    # LINE POWER FLOWS
    @num_of_buses.times do |m|
      @num_of_buses.times do |n|
        if m != n
          sij[m][n][0] = (@vMag[m][0] * iij[m][n][0] - @vMag[m][1] * (-1 * iij[m][n][1])) * 100
          sij[m][n][1] = (@vMag[m][0] * (-1 * iij[m][n][1]) + @vMag[m][1] * (iij[m][n][0])) * 100
        end
      end
    end

    k = 0
    l = 0
    @num_of_buses.times do |m|
      @num_of_buses.times do |n|
        if n > m
          if (sij[m][n][0] != 0) && (sij[m][n][1] != 0)
            z[k] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] unless z[k]
            z[k][0] = m
            z[k][1] = n
            z[k][2] = sij[m][n][0]
            z[k][3] = sij[m][n][1]
            k += 1
          end
        elsif m > n
          if (sij[m][n][0] != 0) && (sij[m][n][1] != 0)
            z[l] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] unless z[l]
            z[l][4] = m
            z[l][5] = n
            z[l][6] = sij[m][n][0]
            z[l][7] = sij[m][n][1]
            l += 1
          end
        end
      end
    end

    pij = []
    qij = []
    @num_of_buses.times do |i|
      pij[i] = []
      qij[i] = []
      @num_of_buses.times do |j|
        pij[i][j] = sij[i][j][0]
        qij[i][j] = sij[i][j][1]
      end
    end

    lij = []
    @num_of_lines.times do |i|
      lij[i] = [0, 0]
    end

    @num_of_lines.times do |m|
      val_p = from_bus[m]
      val_q = to_bus[m]
      lij[m][0] = sij[val_p][val_q][0] + sij[val_q][val_p][0]
      lij[m][1] = sij[val_p][val_q][1] + sij[val_q][val_p][1]
    end

    @num_of_lines.times do |m|
      z[m][8] = lij[m][0]
      z[m][9] = lij[m][1]
    end

    @line_loss_1 = 0
    @line_loss_2 = 0

    @num_of_lines.times do |i|
      @line_loss_1 += z[i][8]
      @line_loss_2 += z[i][9]
    end

    z
  end

  def calculate_power_injections(y_bus)
    p_injection = []
    q_injection = []

    @num_of_buses.times do |i|
      si = [0, 0]
      @num_of_buses.times do |k|
        si[0] += (@vMag[i][0] * @vMag[k][0] * y_bus[i][k][0] - 
                  @vMag[i][0] * @vMag[k][1] * y_bus[i][k][1] - 
                  (-1 * @vMag[i][1]) * @vMag[k][0] * y_bus[i][k][1] - 
                  (-1 * @vMag[i][1]) * @vMag[k][1] * y_bus[i][k][0]) * 100
        si[1] += (@vMag[i][0] * @vMag[k][0] * y_bus[i][k][1] + 
                  @vMag[i][0] * @vMag[k][1] * y_bus[i][k][0] + 
                  (-1 * @vMag[i][1]) * @vMag[k][0] * y_bus[i][k][0] - 
                  (-1 * @vMag[i][1]) * @vMag[k][1] * y_bus[i][k][1]) * 100
      end
      p_injection[i] = si[0]
      q_injection[i] = -1 * si[1]
    end

    [p_injection, q_injection]
  end

  def calculate_generated_power
    power_generated = []
    reactive_generated = []

    @num_of_buses.times do |i|
      power_generated[i] = @p_injection[i] + (@pl_data[i] * 100)
      reactive_generated[i] = @q_injection[i] + (@ql_data[i] * 100)
    end

    [power_generated, reactive_generated]
  end

  def calculate_totals
    {
      pTotal: @p_injection.sum,
      qTotal: @q_injection.sum,
      pgTotal: @power_generated.sum,
      qgTotal: @reactive_generated.sum,
      plTotal: @pl_data.sum,
      qlTotal: @ql_data.sum
    }
  end

  def build_results_hash(y_bus, from_bus, to_bus)
    {
      num_of_buses: @num_of_buses,
      types: @types,
      v_data: @v_data,
      d_data: @d_data,
      p_data: @p_data,
      q_data: @q_data,
      del_degree: @del_degree,
      z: @z,
      p_injection: @p_injection,
      q_injection: @q_injection,
      power_generated: @power_generated,
      reactive_generated: @reactive_generated,
      totals: @totals,
      y_bus: y_bus,
      from_bus: from_bus,
      to_bus: to_bus,
      pl_data: @pl_data,
      ql_data: @ql_data,
      line_loss_1: @line_loss_1,
      line_loss_2: @line_loss_2
    }
  end

  def count_load_buses
    @num_of_buses.times.count { |i| @params["type-#{i + 1}"] == 'load' }
  end

  def get_load_bus_numbers
    @num_of_buses.times.select { |i| @params["type-#{i + 1}"] == 'load' }
  end
end 