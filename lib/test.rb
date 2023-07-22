require_relative 'cramers_rule'
require 'pry'
require 'rb-readline'

params = {}
params['type-1'] = 'slack'
params['v1'] = '1.02'
params['d1'] = '0'
params['p1'] = nil
params['q1'] = nil

params['type-2'] = 'generator'
params['v2'] = '1.05'
params['d2'] = nil
params['p2'] = '0.5'
params['q2'] = nil

params['type-3'] = 'load'
params['v3'] = nil
params['d3'] = nil
params['p3'] = '-1.0'
params['q3'] = '-0.6'

params['from-1'] = '1'
params['to-1'] = '2'
params['impr-1'] = '10'
params['impi-1'] = '-20'

params['from-2'] = '1'
params['to-2'] = '3'
params['impr-2'] = '5'
params['impi-2'] = '-15'

params['from-3'] = '2'
params['to-3'] = '3'
params['impr-3'] = '20'
params['impi-3'] = '-40'

@v_data = []
@d_data = []
@p_data = []
@q_data = []

@all_data = {}
num_of_buses = 0
num_of_load_busses = 0
num_of_lines = 0
process = true

params.each do |key, value|
  num_of_buses += 1 if key.include?('type') # count the number of busses present
  num_of_lines += 1 if key.include?('from') # count the number of lines present
end

#### BUILD THE Y BUS MATRIX ####
y_bus = Array.new

num_of_buses.times do |i| # Initialize empty nxn Y Bus matrix
  y_bus[i] = [] unless y_bus[i]
  num_of_buses.times do |j|
    y_bus[i].push([0,0])
  end
end

num_of_lines.times do |i| # Fill everything but diagonal in form [R, I]
  imp_r = -1 * params["impr-#{i + 1}"].to_f
  imp_i = -1 * params["impi-#{i + 1}"].to_f

  imp_r = 0.0 if imp_r == -0.0
  imp_i = 0.0 if imp_i == -0.0
  loc1 = params["from-#{i + 1}"].to_i - 1
  loc2 = params["to-#{i + 1}"].to_i - 1
  y_bus[loc1][loc2] = [imp_r, imp_i]
  y_bus[loc2][loc1] = [imp_r, imp_i]
end

y_bus.each_with_index do |line_entry, i|
  sum_r = 0.0
  sum_i = 0.0
  line_entry.each do |values|
    sum_r = sum_r + values[0]
    sum_i = sum_i + values[1]
  end

  sum_r = -1 * sum_r if sum_r != 0.0
  sum_i = -1 * sum_i if sum_i != 0.0

  y_bus[i][i] = [sum_r, sum_i]
end

#### FIND ALL UNKNOWNS AND BUILD EQUATIONS ####
unknowns = {}

num_of_buses.times do |i|
  if params["type-#{i + 1}"] == 'generator'
    unknowns["d#{i + 1}"] = 0.0
    @p_data[i] = params["p#{i + 1}"].to_f
    @v_data[i] = params["v#{i + 1}"].to_f
 #   @all_data["p#{i}"] = params["p#{i + 1}"].to_f
 #   @all_data["v#{i}"] = params["v#{i + 1}"].to_f

    # Initialize Delta to 0 and q for Generator busses
    @d_data[i] = 0.0
    @q_data[i] = 0.0
 #   @all_data["d#{i}"] = 0.0
 #   @all_data["q#{i}"] = ''
  elsif params["type-#{i + 1}"] == 'load'
    unknowns["d#{i + 1}"] = 0.0
    unknowns["v#{i + 1}"] = 0.0
    @p_data[i] = params["p#{i + 1}"].to_f
    @q_data[i] = params["q#{i + 1}"].to_f
  #  @all_data["p#{i}"] = params["p#{i + 1}"].to_f
  #  @all_data["q#{i}"] = params["q#{i + 1}"].to_f

    # Initialize Voltage and Angle for Load busses
    @v_data[i] = 1.0
    @d_data[i] = 0.0
 #   @all_data["v#{i}"] = 1.0
 #   @all_data["d#{i}"] = 0.0
    num_of_load_busses += 1

  else # for Slack busses
    @v_data[i] = params["v#{i + 1}"].to_f
    @d_data[i] = params["d#{i + 1}"].to_f
    @p_data[i] = 0.0
    @q_data[i] = 0.0
  #  @all_data["v#{i}"] = params["v#{i + 1}"].to_f
  #  @all_data["d#{i}"] = params["d#{i + 1}"].to_f
  #  @all_data["p#{i}"] = ''
  #  @all_data["q#{i}"] = ''
  end
end

unknowns = unknowns.sort.to_h

binding.pry
iteteration = 0
while(process)
  processing_p_values = Array.new(num_of_buses, 0)
  processing_q_values = Array.new(num_of_buses, 0)

  num_of_buses.times do |i|
    num_of_buses.times do |k|
      processing_p_values[i] = processing_p_values[i] + @v_data[i] * @v_data[k]*(y_bus[i][k][0]*cos(@d_data[i]-@d_data[k]) + y_bus[i][k][1]*sin(@d_data[i]-@d_data[k]))
      processing_q_values[i] = processing_q_values[i] + @v_data[i] * @v_data[k]*(y_bus[i][k][0]*sin(@d_data[i]-@d_data[k]) - y_bus[i][k][1]*cos(@d_data[i]-@d_data[k]))
    end
  end

    # Checking Q-limit violations..
    #if Iter <= 7 && Iter > 2    % Only checked up to 7th iterations..
     #   for n = 2:nbus
      #      if type(n) == 2
       #         QG = Q(n)+Ql(n);
        #        if QG < Qmin(n)
         #           V(n) = V(n) + 0.01;
          #      elseif QG > Qmax(n)
           #         V(n) = V(n) - 0.01;
            #    end
     #       end
      #   end
    #end

  # Calculate change from specified value
    dPa = []
    num_of_buses.times do |i|
      dPa[i] = @p_data[i] - processing_p_values[i]
    end 
    
    dQa = []
    num_of_buses.times do |i|
      dQa[i] = @q_data[i] - processing_q_values[i]
    end 

    k = 1
    dQ = Array.new(num_of_load_busses, 0) # NUmber of load busses
    
    num_of_buses.times do |i|
      if params["type-#{i + 1}"] == 'load'
        dQ[k] = dQa[i] ## check this line in dQ(k,1) = dQa(i);
        k += 1
      end
    end

    dP = dPa(2:nbus);  ## DO these two lines 1 and one below
    M = [dP; dQ];       #Mismatch Vector

## Jacobian
    # J1 - Derivative of Real Power Injections with Angles..
    j1 = zeros(nbus-1,nbus-1);
    for i = 1:(nbus-1)
        m = i+1;
        for k = 1:(nbus-1)
            n = k+1;
            if n == m
                for n = 1:nbus
                    J1(i,k) = J1(i,k) + V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                end
                J1(i,k) = J1(i,k) - V(m)^2*B(m,m);
            else
                J1(i,k) = V(m)* V(n)*(G(m,n)*sin(del(m)-del(n)) - B(m,n)*cos(del(m)-del(n)));
            end
        end
    end














  unknowns.each do |key, value|
    if key.include?("d")
      unknowns[key] = 0.0
    elsif key.include?("v")
      unknowns[key] = 0.0
    end
  end 

  unknowns.each do |key, value|
    bus_num_in_question = /\d+/.match(key).to_s.to_i - 1
    if key.include?("d")
      num_of_buses.times do |i|
        mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
        angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
        unknowns[key] = unknowns[key] + (mag * @all_data["v#{bus_num_in_question}"] * @all_data["v#{i}"] * Math.cos(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"]))
        unknowns[key] = unknowns[key] - @all_data["p#{bus_num_in_question}"] if i == 0
      end
    elsif key.include?("v")
      num_of_buses.times do |i|
        mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
        angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
        unknowns[key] = unknowns[key] - (mag * @all_data["v#{bus_num_in_question}"] * @all_data["v#{i}"] * Math.sin(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"]))
        unknowns[key] = unknowns[key] - @all_data["q#{bus_num_in_question}"] if i == 0
      end
    end
  end

  #### CALCULATE JACOBIAN ####
  jacobian = Array.new

  num_of_buses.times do |i|
    jacobian[i] = [] unless jacobian[i]
    num_of_buses.times do |j|
      jacobian[i][j] = 0
    end
  end

  row_num = 0
  unknowns.each do |key, value|
    bus_num_in_question = /\d+/.match(key).to_s.to_i - 1
    if key.include?("d") #use COSINE rules
      col_num = 0
      unknowns.each do |differentiator, val_2|
        diff_num = /\d+/.match(differentiator).to_s.to_i - 1
        if differentiator.include?("d") # Use angle differentiation
          if diff_num == bus_num_in_question
            num_of_buses.times do |i|
              mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
              angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
              if i != bus_num_in_question
                jacobian[row_num][col_num] = jacobian[row_num][col_num] + @all_data["v#{i}"].abs * @all_data["v#{bus_num_in_question}"].abs * mag * Math.sin(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
              end
            end
          else
            num_of_buses.times do |i|
              if i == diff_num
                mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
                angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
                jacobian[row_num][col_num] = jacobian[row_num][col_num] - @all_data["v#{i}"].abs * @all_data["v#{bus_num_in_question}"].abs * mag * Math.sin(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
              end
            end
          end
        else
          if diff_num == bus_num_in_question
            num_of_buses.times do |i|
              mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
              angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
              if i == diff_num
                jacobian[row_num][col_num] = jacobian[row_num][col_num] + (2 * @all_data["v#{i}"].abs * mag * Math.cos(angle))
              else
                jacobian[row_num][col_num] = jacobian[row_num][col_num] + (@all_data["v#{i}"].abs * mag * Math.cos(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"]))
              end
            end
          else
            num_of_buses.times do |i|
              if i == diff_num
                mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
                angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
                jacobian[row_num][col_num] = jacobian[row_num][col_num] + @all_data["v#{bus_num_in_question}"].abs * mag * Math.cos(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
              end
            end
          end
        end
      col_num += 1
      end
    elsif key.include?("v")
      col_num = 0
      unknowns.each do |differentiator, val_2|
        diff_num = /\d+/.match(differentiator).to_s.to_i - 1
        if differentiator.include?("d") # Use angle differentiation
          if diff_num == bus_num_in_question
            num_of_buses.times do |i|
              if i != bus_num_in_question
                mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
                angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
                jacobian[row_num][col_num] = jacobian[row_num][col_num] + @all_data["v#{i}"].abs * @all_data["v#{bus_num_in_question}"].abs * mag * Math.cos(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
              end
            end
          else
            num_of_buses.times do |i|
              if i == diff_num
                mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
                angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
                jacobian[row_num][col_num] = jacobian[row_num][col_num] - @all_data["v#{i}"].abs * @all_data["v#{bus_num_in_question}"].abs * mag * Math.cos(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
              end
            end 
          end
        else
          if diff_num == bus_num_in_question
            num_of_buses.times do |i|
              mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
              angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
              if i == diff_num
                jacobian[row_num][col_num] = jacobian[row_num][col_num] - (2 * @all_data["v#{i}"].abs * mag * Math.sin(angle))
              else
                jacobian[row_num][col_num] = jacobian[row_num][col_num] - (@all_data["v#{i}"].abs * mag * Math.sin(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"]))
              end
            end
          else
            num_of_buses.times do |i|
              if i == diff_num
                mag = ((y_bus[bus_num_in_question][i][0])** 2 + (y_bus[bus_num_in_question][i][1])**2)**0.5
                angle = Math.atan(y_bus[bus_num_in_question][i][1]/y_bus[bus_num_in_question][i][0])
                jacobian[row_num][col_num] = jacobian[row_num][col_num] - @all_data["v#{bus_num_in_question}"].abs * mag * Math.sin(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
              end
            end
          end
        end
      col_num += 1
      end
    end
    row_num += 1
  end
### Everything verified correct up to here

  #### SOLVE USING CRAMERS RULE ####
  unknown_vector = []
  unknowns.each do |key, value|
    unknown_vector.push(value)
  end

  matrix = Matrix[*jacobian]

  cramer = CramersRule.new
  unknown_vector = cramer.cramers_rule(matrix, unknown_vector)

  i = 0
  unknowns.each do |key, value|
    bus_num_in_question = /\d+/.match(key).to_s.to_i - 1
    if key.include?("d")
      @all_data["d#{bus_num_in_question}"] = @all_data["d#{bus_num_in_question}"] + unknown_vector[i]
    elsif key.include?("v")
      @all_data["v#{bus_num_in_question}"] = @all_data["v#{bus_num_in_question}"] + unknown_vector[i]
    end
    i += 1
  end

  unknown_vector.each do |value|
    if value >= -0.0000001 && value <= 0.0000001
      process = false
    else
      process = true
      break
    end
  end
  #binding.pry
end

@all_data.each do |key, value|
  if value == ''
    @all_data[key] = 0
    if key.include?("p")
      bus_num_in_question = /\d+/.match(key).to_s.to_i
      num_of_buses.times do |i|
        mag = ((y_bus[bus_num_in_question - 1][i][0])** 2 + (y_bus[bus_num_in_question - 1][i][1])**2)**0.5
        angle = Math.atan(y_bus[bus_num_in_question - 1][i][1]/y_bus[bus_num_in_question - 1][i][0])
        @all_data[key] = @all_data[key] + mag * @all_data["v#{bus_num_in_question}"] * @all_data["v#{i}"] * Math.cos(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
      end
    elsif key.include?("q")
      bus_num_in_question = /\d+/.match(key).to_s.to_i
      num_of_buses.times do |i|
        mag = ((y_bus[bus_num_in_question - 1][i][0])** 2 + (y_bus[bus_num_in_question - 1][i][1])**2)**0.5
        angle = Math.atan(y_bus[bus_num_in_question - 1][i][1]/y_bus[bus_num_in_question - 1][i][0])
        @all_data[key] = @all_data[key] - mag * @all_data["v#{bus_num_in_question}"] * @all_data["v#{i}"] * Math.sin(angle - @all_data["d#{bus_num_in_question}"] + @all_data["d#{i}"])
      end
    end
  end
end

p @all_data
