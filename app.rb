# frozen_string_literal: true

require 'sinatra'
require_relative 'lib/cramers_rule'
require_relative 'lib/y_bus_creator'
require 'csv'
require 'webrick'
require 'webrick/https'
require 'openssl'

set :bind, '0.0.0.0'
set :protection, except: :host
set :allowed_hosts, ['power-flow-analysis.fly.dev']

# cert = OpenSSL::X509::Certificate.new File.read 'c:/Apache24/htdocs/server.crt'
# pkey = OpenSSL::PKey::RSA.new File.read 'c:/Apache24/htdocs/server.key'

# server = WEBrick::HTTPServer.new(:Port => 4567,
#                                 :SSLEnable => true,
#                                 :SSLCertificate => cert,
#                                 :SSLPrivateKey => pkey)

get('/') do
  erb :index
end

get('/manual') do
  erb :manual
end

get('/info') do
  erb :info
end

get('/about') do
  erb :about
end

get('/download/bus') do
  send_file 'bus_example.csv', filename: 'bus_example.csv'
end

get('/download/line') do
  send_file 'line_example.csv', filename: 'line_example.csv'
end

get('/download/:time') do
  time = params['time'].to_s
  send_file "results/PowerFlowAnalysis-NR-#{time}.csv", filename: "PowerFlowAnalysis-NR-#{time}.csv"
end

post('/check') do
  @bus_data = []
  @line_data = []

  bus_spreadsheet_content = params[:busFile][:tempfile].read
  @all_bus_lines = bus_spreadsheet_content.split("\r\n")

  @all_bus_lines.each_with_index do |line, i|
    next if i.zero?

    line.split(',').each { |value| @bus_data.push(value) }
  end

  line_spreadsheet_content = params[:lineFile][:tempfile].read

  @all_line_lines = line_spreadsheet_content.split("\r\n")
  @all_line_lines.each_with_index do |line, i|
    next if i.zero?

    line.split(',').each { |value| @line_data.push(value) }
  end
  # {}"#{@bus_data.inspect}"
  erb :post_check
end

post('/analyze') do
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
  y_bus = y_bus_creator.create_y_bus(@num_of_buses)
  from_bus = y_bus_creator.return_from_bus_list
  to_bus = y_bus_creator.return_to_bus_list

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

  p_specified = @p_data
  q_specified = @q_data

  tolerance = 1
  iteration_num = 1

  while tolerance > 0.000001
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

  vMag = []
  @del_degree = []

  @num_of_buses.times do |i|
    vMag[i] = [ 0, 0 ]
  end

  @num_of_buses.times do |i|
    vMag[i][0] = @v_data[i] * Math.cos(@d_data[i])
    vMag[i][1] = @v_data[i] * Math.sin(@d_data[i])
  end

  @num_of_buses.times do |i|
    @del_degree[i] = (180 * @d_data[i]) / Math::PI
  end

  @z = []
  iij = []
  sij = []
  si = []

  @num_of_buses.times do |i|
    @z[i] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
    si[i] = 0
  end

  @num_of_buses.times do |i|
    iij[i] = []
    sij[i] = []
    @num_of_buses.times do |j|
      iij[i][j] = [ 0, 0 ]
      sij[i][j] = [ 0, 0 ]
    end
  end

  i_matrix = []

  # BUS CURRENT INJECTIONS
  @num_of_buses.times do |i|
    i_matrix[i] = [ 0, 0 ]

    @num_of_buses.times do |j|
      i_matrix[i][0] = i_matrix[i][0] + (y_bus[i][j][0] * vMag[j][0] - y_bus[i][j][1] * vMag[j][1])
      i_matrix[i][1] = i_matrix[i][1] + (y_bus[i][j][1] * vMag[j][0] + y_bus[i][j][0] * vMag[j][1])
    end
  end

  iAngle = []
  iMag = []
  @num_of_buses.times do |i|
    iMag[i] = (i_matrix[i][0]**2 + i_matrix[i][1]**2)**0.5
    iAngle[i] = Math.atan(i_matrix[i][1] / i_matrix[i][0]) ## If wrong final result, change to be in accordance
  end

  # LINE CURRENT FLOWS
  num_of_lines.times do |m|
    val_p = from_bus[m]
    val_q = to_bus[m]
    real_part = vMag[val_p][0] - vMag[val_q][0]
    imag_part = vMag[val_p][1] - vMag[val_q][1]
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
        sij[m][n][0] = (vMag[m][0] * iij[m][n][0] - vMag[m][1] * (-1 * iij[m][n][1])) * 100
        sij[m][n][1] = (vMag[m][0] * (-1 * iij[m][n][1]) + vMag[m][1] * (iij[m][n][0])) * 100
      end
    end
  end

  k = 0
  l = 0
  @num_of_buses.times do |m|
    @num_of_buses.times do |n|
      if n > m
        if (sij[m][n][0] != 0) && (sij[m][n][1] != 0)
          @z[k] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] unless @z[k]
          @z[k][0] = m
          @z[k][1] = n
          @z[k][2] = sij[m][n][0]
          @z[k][3] = sij[m][n][1]
          k += 1
        end
      elsif m > n
        if (sij[m][n][0] != 0) && (sij[m][n][1] != 0)
          @z[l] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] unless @z[l]
          @z[l][4] = m
          @z[l][5] = n
          @z[l][6] = sij[m][n][0]
          @z[l][7] = sij[m][n][1]
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
  num_of_lines.times do |i|
    lij[i] = [ 0, 0 ]
  end

  num_of_lines.times do |m|
    val_p = from_bus[m]
    val_q = to_bus[m]
    lij[m][0] = sij[val_p][val_q][0] + sij[val_q][val_p][0]
    lij[m][1] = sij[val_p][val_q][1] + sij[val_q][val_p][1]
  end

  num_of_lines.times do |m|
    @z[m][8] = lij[m][0]
    @z[m][9] = lij[m][1]
  end

  @line_loss_1 = 0
  @line_loss_2 = 0

  num_of_lines.times do |i|
    @line_loss_1 += @z[i][8]
    @line_loss_2 += @z[i][9]
  end

  si = []

  @num_of_buses.times do |i|
    si[i] = [ 0, 0 ]
    @num_of_buses.times do |k|
      si[i][0] =
        si[i][0] + (vMag[i][0] * vMag[k][0] * y_bus[i][k][0] - vMag[i][0] * vMag[k][1] * y_bus[i][k][1] - (-1 * vMag[i][1]) * vMag[k][0] * y_bus[i][k][1] - (-1 * vMag[i][1]) * vMag[k][1] * y_bus[i][k][0]) * 100
      si[i][1] =
        si[i][1] + (vMag[i][0] * vMag[k][0] * y_bus[i][k][1] + vMag[i][0] * vMag[k][1] * y_bus[i][k][0] + (-1 * vMag[i][1]) * vMag[k][0] * y_bus[i][k][0] - (-1 * vMag[i][1]) * vMag[k][1] * y_bus[i][k][1]) * 100
    end
  end

  @p_injection = []
  @q_injection = []

  @num_of_buses.times do |i|
    @p_injection[i] = si[i][0]
    @q_injection[i] = -1 * si[i][1]
  end

  @power_generated = []
  @reactive_generated = []

  @num_of_buses.times do |i|
    @power_generated[i] = @p_injection[i] + (@pl_data[i] * 100)
    @reactive_generated[i] = @q_injection[i] + (@ql_data[i] * 100)
  end

  @pTotal = 0
  @p_injection.each { |val| @pTotal += val }

  @qTotal = 0
  @q_injection.each { |val| @qTotal += val }

  @pgTotal = 0
  @power_generated.each { |val| @pgTotal += val }

  @qgTotal = 0
  @reactive_generated.each { |val| @qgTotal += val }

  @plTotal = 0
  @pl_data.each { |val| @plTotal += val }

  @qlTotal = 0
  @ql_data.each { |val| @qlTotal += val }

  # GENERATE RESULTS
  @time = Time.now.strftime('%d-%m-%Y-%H-%M-%S')
  CSV.open("results/PowerFlowAnalysis-NR-#{@time}.csv", 'wb') do |csv|
    csv << [ 'Bus Number', 'Type', 'V', 'D', 'P', 'Q' ]

    @num_of_buses.times do |bus|
      new_line = [ bus + 1 ]
      new_line.push(@types[bus])
      new_line.push(@v_data[bus])
      new_line.push(@d_data[bus])
      new_line.push(@p_data[bus])
      new_line.push(@q_data[bus])
      csv << new_line
    end
    csv << []
    csv << [ 'Newton Raphson Load Flow Analysis' ]
    csv << [ 'Bus #', 'V (pu)', 'Angle (degree)', 'Injection MW', 'Injection MVar', 'Generation MW', 'Generation MVar',
            'Load MW', 'Load MVar' ]

    @num_of_buses.times do |i|
      new_line = [ i + 1 ]
      new_line.push(@v_data[i])
      new_line.push(@del_degree[i])
      new_line.push(@p_injection[i])
      new_line.push(@q_injection[i])
      new_line.push(@power_generated[i])
      new_line.push(@reactive_generated[i])
      new_line.push(@pl_data[i])
      new_line.push(@ql_data[i])
      csv << new_line
    end
    new_line = [ 'Total' ]
    new_line.push('')
    new_line.push('')
    new_line.push(@pTotal)
    new_line.push(@qTotal)
    new_line.push(@pgTotal)
    new_line.push(@qgTotal)
    new_line.push(@plTotal)
    new_line.push(@qlTotal)
    csv << new_line
    csv << []
    csv << [ 'Line Flows and Losses' ]
    csv << [ 'From Bus', 'To Bus', 'P MW', 'Q MVar', 'From Bus', 'To Bus', 'P MW', 'Q MVar', 'Line Loss MW',
            'Line Loss MVar' ]

    @z.each do |row|
      new_line = [ row[0] ]
      new_line.push(row[1])
      new_line.push(row[2])
      new_line.push(row[3])
      new_line.push(row[1])
      new_line.push(row[0])
      new_line.push(row[6])
      new_line.push(row[7])
      new_line.push(row[8])
      new_line.push(row[9])
      csv << new_line
    end

    new_line = [ 'Total Loss' ]
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push(@line_loss_1)
    new_line.push(@line_loss_2)
    csv << new_line
  end

  erb :result

  # send_file "PowerFlowAnalysis-NR-#{time}.csv", :filename => "PowerFlowAnalysis-NR-#{time}.csv"
end
