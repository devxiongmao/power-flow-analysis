# frozen_string_literal: true

require_relative 'cramers_rule'
require 'pry'
require_relative 'y_bus_creator'
require 'rb-readline'

params = { 'type-1' => 'slack', 'v1' => '1.06', 'd1' => '0', 'pg1' => '0', 'qg1' => '0', 'pl1' => '0', 'ql1' => '0', 'qmin1' => '0',
           'qmax1' => '0', 'type-2' => 'generator', 'v2' => '1.045', 'd2' => '0', 'pg2' => '40', 'qg2' => '42.4', 'pl2' => '21.7', 'ql2' => '12.7', 'qmin2' => '-40', 'qmax2' => '50', 'type-3' => 'generator', 'v3' => '1.01', 'd3' => '0', 'pg3' => '0', 'qg3' => '23.4', 'pl3' => '94.2', 'ql3' => '19', 'qmin3' => '0', 'qmax3' => '40', 'type-4' => 'load', 'v4' => '1', 'd4' => '0', 'pg4' => '0', 'qg4' => '0', 'pl4' => '47.8', 'ql4' => '-3.9', 'qmin4' => '0', 'qmax4' => '0', 'type-5' => 'load', 'v5' => '1', 'd5' => '0', 'pg5' => '0', 'qg5' => '0', 'pl5' => '7.6', 'ql5' => '1.6', 'qmin5' => '0', 'qmax5' => '0', 'type-6' => 'generator', 'v6' => '1.07', 'd6' => '0', 'pg6' => '0', 'qg6' => '12.2', 'pl6' => '11.2', 'ql6' => '7.5', 'qmin6' => '-6', 'qmax6' => '24', 'type-7' => 'load', 'v7' => '1', 'd7' => '0', 'pg7' => '0', 'qg7' => '0', 'pl7' => '0', 'ql7' => '0', 'qmin7' => '0', 'qmax7' => '0', 'type-8' => 'generator', 'v8' => '1.09', 'd8' => '0', 'pg8' => '0', 'qg8' => '17.4', 'pl8' => '0', 'ql8' => '0', 'qmin8' => '-6', 'qmax8' => '24', 'type-9' => 'load', 'v9' => '1', 'd9' => '0', 'pg9' => '0', 'qg9' => '0', 'pl9' => '29.5', 'ql9' => '16.6', 'qmin9' => '0', 'qmax9' => '0', 'type-10' => 'load', 'v10' => '1', 'd10' => '0', 'pg10' => '0', 'qg10' => '0', 'pl10' => '9', 'ql10' => '5.8', 'qmin10' => '0', 'qmax10' => '0', 'type-11' => 'load', 'v11' => '1', 'd11' => '0', 'pg11' => '0', 'qg11' => '0', 'pl11' => '3.5', 'ql11' => '1.8', 'qmin11' => '0', 'qmax11' => '0', 'type-12' => 'load', 'v12' => '1', 'd12' => '0', 'pg12' => '0', 'qg12' => '0', 'pl12' => '6.1', 'ql12' => '1.6', 'qmin12' => '0', 'qmax12' => '0', 'type-13' => 'load', 'v13' => '1', 'd13' => '0', 'pg13' => '0', 'qg13' => '0', 'pl13' => '13.5', 'ql13' => '5.8', 'qmin13' => '0', 'qmax13' => '0', 'type-14' => 'load', 'v14' => '1', 'd14' => '0', 'pg14' => '0', 'qg14' => '0', 'pl14' => '14.9', 'ql14' => '5', 'qmin14' => '0', 'qmax14' => '0', 'from-1' => '1', 'to-1' => '2', 'line-resistance-1' => '0.01938', 'line-reactance-1' => '0.05917', 'ground-admittance-1' => '0.0264', 'tap-setting-1' => '1', 'from-2' => '1', 'to-2' => '5', 'line-resistance-2' => '0.05403', 'line-reactance-2' => '0.22304', 'ground-admittance-2' => '0.0246', 'tap-setting-2' => '1', 'from-3' => '2', 'to-3' => '3', 'line-resistance-3' => '0.04699', 'line-reactance-3' => '0.19797', 'ground-admittance-3' => '0.0219', 'tap-setting-3' => '1', 'from-4' => '2', 'to-4' => '4', 'line-resistance-4' => '0.05811', 'line-reactance-4' => '0.17632', 'ground-admittance-4' => '0.017', 'tap-setting-4' => '1', 'from-5' => '2', 'to-5' => '5', 'line-resistance-5' => '0.05695', 'line-reactance-5' => '0.17388', 'ground-admittance-5' => '0.0173', 'tap-setting-5' => '1', 'from-6' => '3', 'to-6' => '4', 'line-resistance-6' => '0.06701', 'line-reactance-6' => '0.17103', 'ground-admittance-6' => '0.0064', 'tap-setting-6' => '1', 'from-7' => '4', 'to-7' => '5', 'line-resistance-7' => '0.01335', 'line-reactance-7' => '0.04211', 'ground-admittance-7' => '0', 'tap-setting-7' => '1', 'from-8' => '4', 'to-8' => '7', 'line-resistance-8' => '0', 'line-reactance-8' => '0.20912', 'ground-admittance-8' => '0', 'tap-setting-8' => '0.978', 'from-9' => '4', 'to-9' => '9', 'line-resistance-9' => '0', 'line-reactance-9' => '0.55618', 'ground-admittance-9' => '0', 'tap-setting-9' => '0.969', 'from-10' => '5', 'to-10' => '6', 'line-resistance-10' => '0', 'line-reactance-10' => '0.25202', 'ground-admittance-10' => '0', 'tap-setting-10' => '0.932', 'from-11' => '6', 'to-11' => '11', 'line-resistance-11' => '0.09498', 'line-reactance-11' => '0.1989', 'ground-admittance-11' => '0', 'tap-setting-11' => '1', 'from-12' => '6', 'to-12' => '12', 'line-resistance-12' => '0.12291', 'line-reactance-12' => '0.25581', 'ground-admittance-12' => '0', 'tap-setting-12' => '1', 'from-13' => '6', 'to-13' => '13', 'line-resistance-13' => '0.06615', 'line-reactance-13' => '0.13027', 'ground-admittance-13' => '0', 'tap-setting-13' => '1', 'from-14' => '7', 'to-14' => '8', 'line-resistance-14' => '0', 'line-reactance-14' => '0.17615', 'ground-admittance-14' => '0', 'tap-setting-14' => '1', 'from-15' => '7', 'to-15' => '9', 'line-resistance-15' => '0', 'line-reactance-15' => '0.11001', 'ground-admittance-15' => '0', 'tap-setting-15' => '1', 'from-16' => '9', 'to-16' => '10', 'line-resistance-16' => '0.03181', 'line-reactance-16' => '0.0845', 'ground-admittance-16' => '0', 'tap-setting-16' => '1', 'from-17' => '9', 'to-17' => '14', 'line-resistance-17' => '0.12711', 'line-reactance-17' => '0.27038', 'ground-admittance-17' => '0', 'tap-setting-17' => '1', 'from-18' => '10', 'to-18' => '11', 'line-resistance-18' => '0.08205', 'line-reactance-18' => '0.19207', 'ground-admittance-18' => '0', 'tap-setting-18' => '1', 'from-19' => '12', 'to-19' => '13', 'line-resistance-19' => '0.22092', 'line-reactance-19' => '0.19988', 'ground-admittance-19' => '0', 'tap-setting-19' => '1', 'from-20' => '13', 'to-20' => '14', 'line-resistance-20' => '0.17093', 'line-reactance-20' => '0.34802', 'ground-admittance-20' => '0', 'tap-setting-20' => '1' }

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

pv_bus_numbers = []
load_bus_numbers = []

@num_of_buses = 0
num_of_load_buses = 0
num_of_pv_busses = 0
num_of_lines = 0

params.each_key do |key|
  @num_of_buses += 1 if key.include?('type') # count the number of busses present
  num_of_lines += 1 if key.include?('from') # count the number of lines present
end

#### BUILD THE Y BUS MATRIX ####
y_bus_creator = YBusCreator.new(@num_of_buses, num_of_lines, params)
y_bus = y_bus_creator.create_y_bus(@num_of_buses, num_of_lines)

#### FIND ALL UNKNOWNS AND BUILD EQUATIONS ####
@num_of_buses.times do |i|
  if params["type-#{i + 1}"] == 'generator'
    num_of_pv_busses += 1
    @types[i] = 'Generator'
    pv_bus_numbers.push(i)
  elsif params["type-#{i + 1}"] == 'load'
    num_of_load_buses += 1
    @types[i] = 'Load'
    load_bus_numbers.push(i)
  else # for Slack busses
    num_of_pv_busses += 1
    @types[i] = 'Slack'
    pv_bus_numbers.push(i)
  end

  @v_data[i] = params["v#{i + 1}"].to_f
  @d_data[i] = params["d#{i + 1}"].to_f
  @pg_data[i] = params["pg#{i + 1}"].to_f / 100
  @qg_data[i] = params["qg#{i + 1}"].to_f / 100
  @pl_data[i] = params["pl#{i + 1}"].to_f / 100
  @ql_data[i] = params["ql#{i + 1}"].to_f / 100
  @qmin[i] = params["qmin#{i + 1}"].to_f / 100
  @qmax[i] = params["qmax#{i + 1}"].to_f / 100
  @p_data[i] = (params["pg#{i + 1}"].to_f - params["pl#{i + 1}"].to_f) / 100
  @q_data[i] = (params["qg#{i + 1}"].to_f - params["ql#{i + 1}"].to_f) / 100
end
binding.pry

p_specified = @p_data
q_specified = @q_data

tolerance = 1
iteration_num = 1

while tolerance > 0.000001
  puts iteration_num
  # Calculate P and Q
  processing_p_values = Array.new(@num_of_buses, 0)
  processing_q_values = Array.new(@num_of_buses, 0)

  @num_of_buses.times do |i|
    @num_of_buses.times do |k|
      processing_p_values[i] =
        processing_p_values[i] + (@v_data[i] * @v_data[k] * (y_bus[i][k][0] * Math.cos(@d_data[i] - @d_data[k]) + y_bus[i][k][1] * Math.sin(@d_data[i] - @d_data[k])))
      processing_q_values[i] =
        processing_q_values[i] + (@v_data[i] * @v_data[k] * (y_bus[i][k][0] * Math.sin(@d_data[i] - @d_data[k]) - y_bus[i][k][1] * Math.cos(@d_data[i] - @d_data[k])))
    end
  end

  if (iteration_num <= 7) && (iteration_num > 2)
    @num_of_buses.times do |n|
      next if n.zero?

      next unless @types[n] == 'Generator'

      qg = processing_q_values[n] + @ql_data[n]
      if qg < @qmin[n]
        @v_data[n] = @v_data[n] + 0.01
      elsif qg > @qmax[n]
        @v_data[n] = @v_data[n] - 0.01
      end
    end
  end

  dPa = []
  dQa = []
  p_specified.each_with_index do |value, i|
    dPa[i] = value - processing_p_values[i]
    dQa[i] = q_specified[i] - processing_q_values[i]
  end

  k = 0
  dQ = Array.new(num_of_load_buses, 0)

  @num_of_buses.times do |i|
    if params["type-#{i + 1}"] == 'load'
      dQ[k] = dQa[i] # CHECK IN MATLAB THIS LINE, ALSO, INDEX AT 0?
      k += 1
    end
  end

  dP = []
  @num_of_buses.times do |i|
    next if i.zero?

    dP.push(dPa[i]) # CHECK IN MATLAB THIS LINE, ALSO, INDEX AT 0?
  end

  # CREATE MISMATCH VECTOR
  error_vector = []
  dP.each do |value|
    error_vector.push(value)
  end

  dQ.each do |value|
    error_vector.push(value)
  end

  # JACOBIAN DERIVATION
  # J1 - Derivative of Real Power Injections with Angles..
  j1 = []

  (@num_of_buses - 1).times do |i|
    j1[i] = []
    (@num_of_buses - 1).times do |k|
      j1[i][k] = 0
    end
  end

  (@num_of_buses - 1).times do |i|
    m = i + 1
    (@num_of_buses - 1).times do |k|
      n = k + 1
      if n == m
        @num_of_buses.times do |n|
          j1[i][k] =
            j1[i][k] + @v_data[m] * @v_data[n] * (-y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) + y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
        end
        j1[i][k] = j1[i][k] - y_bus[m][m][1] * @v_data[m]**2
      else
        j1[i][k] =
          @v_data[m] * @v_data[n] * (y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) - y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
      end
    end
  end

  # J2 - Derivative of real power injections
  j2 = []

  (@num_of_buses - 1).times do |i|
    j2[i] = []
    num_of_load_buses.times do |k|
      j2[i][k] = 0
    end
  end

  (@num_of_buses - 1).times do |i|
    m = i + 1
    num_of_load_buses.times do |k|
      n = load_bus_numbers[k]
      if n == m
        @num_of_buses.times do |n|
          j2[i][k] =
            j2[i][k] + @v_data[n] * (y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) + y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
        end
        j2[i][k] = j2[i][k] + y_bus[m][m][0] * @v_data[m]
      else
        j2[i][k] =
          @v_data[m] * (y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) + y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
      end
    end
  end

  # J3 - Derivative of reactive power injections
  j3 = []

  num_of_load_buses.times do |i|
    j3[i] = []
    (@num_of_buses - 1).times do |k|
      j3[i][k] = 0
    end
  end

  num_of_load_buses.times do |i|
    m = load_bus_numbers[i]
    (@num_of_buses - 1).times do |k|
      n = k + 1
      if n == m
        @num_of_buses.times do |n|
          j3[i][k] =
            j3[i][k] + @v_data[m] * @v_data[n] * (y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) + y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
        end
        j3[i][k] = j3[i][k] - y_bus[m][m][0] * @v_data[m]**2
      else
        j3[i][k] =
          @v_data[m] * @v_data[n] * (-y_bus[m][n][0] * Math.cos(@d_data[m] - @d_data[n]) - y_bus[m][n][1] * Math.sin(@d_data[m] - @d_data[n]))
      end
    end
  end

  # J3 - Derivative of reactive power injections
  j4 = []

  num_of_load_buses.times do |i|
    j4[i] = []
    num_of_load_buses.times do |k|
      j4[i][k] = 0
    end
  end

  num_of_load_buses.times do |i|
    m = load_bus_numbers[i]
    num_of_load_buses.times do |k|
      n = load_bus_numbers[k]
      if n == m
        @num_of_buses.times do |n|
          j4[i][k] =
            j4[i][k] + @v_data[n] * (y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) - y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
        end
        j4[i][k] = j4[i][k] - y_bus[m][m][1] * @v_data[m]
      else
        j4[i][k] =
          @v_data[m] * (y_bus[m][n][0] * Math.sin(@d_data[m] - @d_data[n]) - y_bus[m][n][1] * Math.cos(@d_data[m] - @d_data[n]))
      end
    end
  end

  jacobian = []

  (@num_of_buses + num_of_load_buses - 1).times do |i| # Initialize empty nxn Y Bus matrix
    jacobian[i] = [] unless jacobian[i]
  end

  j1.each_with_index do |row_j1, i|
    row_j1.each_with_index do |value, _j|
      jacobian[i].push(value)
    end
  end

  j2.each_with_index do |row_j2, i|
    row_j2.each do |value|
      jacobian[i].push(value)
    end
  end

  j3.each_with_index do |row_j3, i|
    k = @num_of_buses + i - 1
    row_j3.each do |value|
      jacobian[k].push(value)
    end
  end

  j4.each_with_index do |row_j4, i|
    k = @num_of_buses + i - 1
    row_j4.each do |value|
      jacobian[k].push(value)
    end
  end

  matrix = Matrix[*jacobian]

  cramer = CramersRule.new
  correction_vector = cramer.cramers_rule(matrix, error_vector)

  dTh = []

  (@num_of_buses - 1).times do |i|
    dTh[i] = correction_vector[i]
  end

  dV = []
  num_of_load_buses.times do |i|
    k = (@num_of_buses - 1 + i)
    dV[i] = correction_vector[k]
  end

  @num_of_buses.times do |i|
    next if i.zero?

    @d_data[i] = dTh[i - 1] + @d_data[i]
  end

  k = 0
  @num_of_buses.times do |i|
    next if i.zero?

    if params["type-#{i + 1}"] == 'load'
      @v_data[i] = dV[k] + @v_data[i]
      k += 1
    end
  end

  iteration_num += 1
  absolute = error_vector.map { |value| value.negative? ? -1 * value : value }
  tolerance = absolute.max
end
@p_data = processing_p_values
@q_data = processing_q_values

binding.pry

# GENERATE RESULTS
@time = Time.now.strftime('%d-%m-%Y-%H-%M-%S')
CSV.open("results/PowerFlowAnalysis-NR-#{@time}.csv", 'wb') do |csv|
  csv << ['Bus Number', 'Type', 'V', 'D', 'P', 'Q']

  @num_of_buses.times do |bus|
    new_line = [bus + 1]
    new_line.push(@types[bus])
    new_line.push(@v_data[bus])
    new_line.push(@d_data[bus])
    new_line.push(@p_data[bus])
    new_line.push(@q_data[bus])
    csv << new_line
  end
end
erb :result
